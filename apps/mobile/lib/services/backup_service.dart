import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';

typedef BackupDirectoryProvider = Future<Directory> Function();

class BackupSummary {
  const BackupSummary({
    required this.createdAtUtc,
    required this.sessionCount,
    required this.seriesCount,
    required this.imageCount,
    this.formatVersion = BackupPayloadAdapter.currentFormatVersion,
  });

  final DateTime createdAtUtc;
  final int sessionCount;
  final int seriesCount;
  final int imageCount;
  final int formatVersion;
}

class RestoreResult {
  const RestoreResult({required this.summary, required this.safetyBackup});

  final BackupSummary summary;
  final File safetyBackup;
}

/// A validated, platform-independent representation of database.json.
///
/// The adapter is intentionally independent from Drift and file I/O. This keeps
/// the v1 compatibility rules deterministic and directly unit-testable.
class NormalizedBackupPayload {
  const NormalizedBackupPayload({
    required this.sourceFormatVersion,
    required this.manifest,
    required this.data,
  });

  final int sourceFormatVersion;
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> data;

  BackupSummary get summary => BackupSummary(
    createdAtUtc: DateTime.parse(manifest['createdAtUtc'] as String).toUtc(),
    sessionCount: manifest['sessionCount'] as int,
    seriesCount: manifest['seriesCount'] as int,
    imageCount: manifest['imageCount'] as int,
    formatVersion: sourceFormatVersion,
  );
}

/// Converts every supported SCB1 payload to the schema-3 JSON shape.
class BackupPayloadAdapter {
  const BackupPayloadAdapter._();

  static const currentFormatVersion = 3;
  static const _formatName = 'shooting-companion-backup';

  static NormalizedBackupPayload normalize({
    required Map<String, dynamic> manifest,
    required Map<String, dynamic> data,
  }) {
    if (manifest['format'] != _formatName) {
      throw const FormatException('Onbekend back-upformaat.');
    }
    final version = _integer(manifest['formatVersion'], 'formatVersion');
    if (version < 1 || version > currentFormatVersion) {
      throw const FormatException('Niet-ondersteunde back-upversie.');
    }
    final createdAt = manifest['createdAtUtc'];
    if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
      throw const FormatException('Ongeldige aanmaakdatum in manifest.');
    }

    final normalized = switch (version) {
      1 => _upgradeV2(_upgradeV1(data)),
      2 => _upgradeV2(data),
      _ => _normalizeV3(data),
    };
    final sessionCount = _integer(manifest['sessionCount'], 'sessionCount');
    final seriesCount = _integer(manifest['seriesCount'], 'seriesCount');
    final imageCount = _integer(manifest['imageCount'], 'imageCount');
    if (sessionCount != (normalized['sessions']! as List).length ||
        seriesCount != (normalized['series']! as List).length ||
        imageCount != (normalized['images']! as List).length) {
      throw const FormatException(
        'Recordaantallen in het manifest komen niet overeen.',
      );
    }

    return NormalizedBackupPayload(
      sourceFormatVersion: version,
      manifest: Map<String, dynamic>.from(manifest),
      data: normalized,
    );
  }

  static Map<String, dynamic> _normalizeV2(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final key in _v2Tables) {
      result[key] = _table(data, key);
    }
    return result;
  }

  static Map<String, dynamic> _normalizeV3(Map<String, dynamic> data) {
    final result = _normalizeV2(data);
    _validateLibraryRelations(result);
    return result;
  }

  static Map<String, dynamic> _upgradeV2(Map<String, dynamic> data) {
    final result = _normalizeV2(data);
    result['cartridges'] = (result['cartridges']! as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map)
        ..['builtIn'] = true
        ..['archived'] = false;
      return row;
    }).toList();
    for (final table in ['ammoLots', 'ranges', 'targetProfiles']) {
      result[table] = (result[table]! as List).map((value) {
        final row = Map<String, dynamic>.from(value as Map);
        row['archived'] = false;
        return row;
      }).toList();
    }
    _validateLibraryRelations(result);
    return result;
  }

  static void _validateLibraryRelations(Map<String, dynamic> data) {
    final cartridgeIds = (data['cartridges']! as List)
        .map((value) => (value as Map)['id'])
        .whereType<String>()
        .toSet();
    for (final value in data['ammoLots']! as List) {
      final row = value as Map;
      if (row['id'] is! String || !cartridgeIds.contains(row['cartridgeId'])) {
        throw const FormatException(
          'Munitieprofiel verwijst naar een onbekend kaliber.',
        );
      }
    }
  }

  static Map<String, dynamic> _upgradeV1(Map<String, dynamic> data) {
    final firearms = _table(data, 'firearms');
    final cartridges = _table(data, 'cartridges');
    final ammoLots = _table(data, 'ammoLots');
    final ranges = _table(data, 'ranges');
    final targets = _table(data, 'targetProfiles');
    final goals = _table(data, 'goals');
    final preferences = _table(data, 'preferences');
    final oldSessions = _table(data, 'sessions');
    final oldSeries = _table(data, 'series');
    final oldImpacts = _table(data, 'impacts');
    final oldImages = _table(data, 'images');

    final sessions = oldSessions.map((row) {
      final copy = Map<String, dynamic>.from(row);
      copy['updatedAtUtc'] = copy['endedAtUtc'] ?? copy['startedAtUtc'];
      copy['photoSafetyAcknowledgedAtUtc'] = null;
      return copy;
    }).toList();

    final impactsBySeries = <String, List<Map<String, dynamic>>>{};
    final impacts = oldImpacts.map((row) {
      final copy = Map<String, dynamic>.from(row)
        ..remove('origin')
        ..remove('confidence');
      copy['sourceImageId'] = null;
      copy['imageXNormalized'] = null;
      copy['imageYNormalized'] = null;
      copy['multiplicity'] ??= 1;
      final seriesId = copy['seriesId'];
      if (seriesId is! String) {
        throw const FormatException('Treffer zonder geldige reeks.');
      }
      impactsBySeries.putIfAbsent(seriesId, () => []).add(copy);
      return copy;
    }).toList();

    final cartridgeByAmmoLot = <String, String>{};
    for (final ammoLot in ammoLots) {
      final id = ammoLot['id'];
      final cartridgeId = ammoLot['cartridgeId'];
      if (id is String && cartridgeId is String) {
        cartridgeByAmmoLot[id] = cartridgeId;
      }
    }

    final seriesById = <String, Map<String, dynamic>>{};
    final series = oldSeries.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final id = copy['id'];
      if (id is! String) {
        throw const FormatException('Reeks zonder geldige id.');
      }
      final seriesImpacts = impactsBySeries[id] ?? const [];
      final shotCount = seriesImpacts.isEmpty
          ? _integer(copy['expectedShots'] ?? 0, 'expectedShots')
          : seriesImpacts.fold<int>(
              0,
              (sum, impact) =>
                  sum + _integer(impact['multiplicity'] ?? 1, 'multiplicity'),
            );
      final maximumPerShot = targetMaximumFromJson(copy['targetProfileJson']);
      final ammoLotId = copy['ammoLotId'];
      copy
        ..remove('expectedShots')
        ..['cartridgeId'] = ammoLotId is String
            ? cartridgeByAmmoLot[ammoLotId]
            : null
        ..['shotCount'] = shotCount
        ..['maximumPossibleScore'] = shotCount * maximumPerShot
        ..['notes'] = null
        ..['updatedAtUtc'] = copy['confirmedAtUtc'] ?? copy['createdAtUtc'];
      seriesById[id] = copy;
      return copy;
    }).toList();

    final primaryImageSeries = <String>{};
    final images = oldImages.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final seriesId = copy['seriesId'];
      if (seriesId is! String || !seriesById.containsKey(seriesId)) {
        throw const FormatException('Foto zonder geldige reeks.');
      }
      final sessionId = seriesById[seriesId]!['sessionId'];
      if (sessionId is! String) {
        throw const FormatException('Foto zonder geldige sessie.');
      }
      final isPrimary =
          copy['kind'] == 'after' && primaryImageSeries.add(seriesId);
      copy
        ..remove('kind')
        ..['sessionId'] = sessionId
        ..['role'] = isPrimary ? 'primaryScoringPhoto' : 'attachment'
        ..['caption'] = null
        ..['updatedAtUtc'] = copy['createdAtUtc'];
      return copy;
    }).toList();

    return {
      'sessions': sessions,
      'series': series,
      'impacts': impacts,
      'images': images,
      'photoAlignments': <Map<String, dynamic>>[],
      'firearms': firearms,
      'cartridges': cartridges,
      'ammoLots': ammoLots,
      'ranges': ranges,
      'goals': goals,
      'settings': preferences,
      'targetProfiles': targets,
    };
  }

  static int targetMaximumFromJson(Object? source) {
    if (source is! String) {
      throw const FormatException('Doelprofielsnapshot ontbreekt.');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Ongeldig doelprofielsnapshot.');
    }
    final rings = decoded['rings'];
    if (rings is! List || rings.isEmpty) {
      throw const FormatException('Doelprofiel bevat geen scoringsringen.');
    }
    var maximum = 0;
    for (final ring in rings) {
      if (ring is! Map) {
        throw const FormatException('Ongeldige scoringsring.');
      }
      final value = _integer(ring['value'], 'ring.value');
      if (value > maximum) maximum = value;
    }
    return maximum;
  }

  static List<Map<String, dynamic>> _table(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is! List) {
      throw FormatException('Tabel $key ontbreekt.');
    }
    return value.map((row) {
      if (row is! Map) {
        throw FormatException('Ongeldig record in tabel $key.');
      }
      return row.cast<String, dynamic>();
    }).toList();
  }

  static int _integer(Object? value, String field) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('Ongeldige gehele waarde voor $field.');
  }

  static const _v2Tables = {
    'sessions',
    'series',
    'impacts',
    'images',
    'photoAlignments',
    'firearms',
    'cartridges',
    'ammoLots',
    'ranges',
    'goals',
    'settings',
    'targetProfiles',
  };
}

/// Shared integrity gate for every media file restored from a backup.
class BackupMediaIntegrity {
  const BackupMediaIntegrity._();

  static void verify({
    required String imageId,
    required List<int> bytes,
    required String recordSha256,
    required int recordSizeBytes,
    required String manifestSha256,
    int? manifestSizeBytes,
  }) {
    final digest = sha256.convert(bytes).toString();
    if (digest != recordSha256 || digest != manifestSha256) {
      throw FormatException('Controlegetal van foto $imageId klopt niet.');
    }
    if (bytes.length != recordSizeBytes ||
        (manifestSizeBytes != null && bytes.length != manifestSizeBytes)) {
      throw FormatException('Bestandsgrootte van foto $imageId klopt niet.');
    }
  }
}

class BackupService {
  BackupService(
    this.database, {
    BackupDirectoryProvider? temporaryDirectory,
    BackupDirectoryProvider? applicationDocumentsDirectory,
    DateTime Function()? now,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _applicationDocumentsDirectory =
           applicationDocumentsDirectory ?? getApplicationDocumentsDirectory,
       _now = now ?? DateTime.now;

  static const _magic = [0x53, 0x43, 0x42, 0x31]; // SCB1
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  final AppDatabase database;
  final BackupDirectoryProvider _temporaryDirectory;
  final BackupDirectoryProvider _applicationDocumentsDirectory;
  final DateTime Function() _now;

  Future<File> createEncryptedBackup(String password) async {
    if (password.length < 10) {
      throw const FormatException(
        'Gebruik een wachtwoord van minstens 10 tekens.',
      );
    }
    final archive = await _createArchive();
    final zipBytes = ZipEncoder().encode(archive);
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final key = await _deriveKey(password, salt);
    final box = await AesGcm.with256bits().encrypt(
      zipBytes,
      secretKey: key,
      nonce: nonce,
    );

    final container = BytesBuilder(copy: false)
      ..add(_magic)
      ..add(salt)
      ..add(nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    final directory = Directory(
      path.join(
        (await _temporaryDirectory()).path,
        'shooting_companion_exports',
      ),
    );
    await directory.create(recursive: true);
    final stamp = _now().toUtc().toIso8601String().replaceAll(
      RegExp('[:.]'),
      '-',
    );
    final file = File(
      path.join(directory.path, 'shooting-companion-$stamp.scbackup'),
    );
    return file.writeAsBytes(container.takeBytes(), flush: true);
  }

  Future<BackupSummary> inspectEncryptedBackup(
    File file,
    String password,
  ) async {
    final archive = await _decryptArchive(await file.readAsBytes(), password);
    return _readPayload(archive).summary;
  }

  Future<RestoreResult> restoreEncryptedBackup(
    File file,
    String password,
  ) async {
    final archive = await _decryptArchive(await file.readAsBytes(), password);
    final payload = _readPayload(archive);
    final data = payload.data;

    final cartridges = _rows(data, 'cartridges', CartridgeRecord.fromJson);
    final ranges = _rows(data, 'ranges', RangeRecord.fromJson);
    final firearms = _rows(data, 'firearms', FirearmRecord.fromJson);
    final ammoLots = _rows(data, 'ammoLots', AmmoLotRecord.fromJson);
    final targetProfiles = _rows(
      data,
      'targetProfiles',
      TargetProfileRecord.fromJson,
    );
    final sessions = _rows(data, 'sessions', SessionRecord.fromJson);
    final series = _rows(data, 'series', SeriesRecord.fromJson);
    final impacts = _rows(data, 'impacts', ImpactRecord.fromJson);
    final goals = _rows(data, 'goals', GoalRecord.fromJson);
    final settings = _rows(data, 'settings', PreferenceRecord.fromJson);
    final imageRecords = _rows(data, 'images', ImageAssetRecord.fromJson);
    final alignments = _rows(
      data,
      'photoAlignments',
      PhotoAlignmentRecord.fromJson,
    );

    // A safety backup must exist before either files or records are replaced.
    final safetyBackup = await createEncryptedBackup(password);
    final oldImages = await database.select(database.imageAssets).get();
    final appRoot = await _applicationDocumentsDirectory();
    final imageDirectory = Directory(
      path.join(appRoot.path, 'target_images', 'originals'),
    );
    await imageDirectory.create(recursive: true);
    final stagedFiles = <File>[];
    final restoredImages = <ImageAssetRecord>[];

    try {
      final fileEntries = _mediaEntries(payload, imageRecords);
      for (final record in imageRecords) {
        final entry = fileEntries[record.id];
        if (entry == null) {
          throw FormatException(
            'Bestandsbeschrijving voor foto ${record.id} ontbreekt.',
          );
        }
        final archived = archive.findFile(entry.archivePath);
        if (archived == null) {
          throw FormatException('Foto ${record.id} ontbreekt in de back-up.');
        }
        final bytes = Uint8List.fromList(archived.content as List<int>);
        BackupMediaIntegrity.verify(
          imageId: record.id,
          bytes: bytes,
          recordSha256: record.sha256,
          recordSizeBytes: record.sizeBytes,
          manifestSha256: entry.sha256,
          manifestSizeBytes: entry.sizeBytes,
        );
        final destination = await _uniqueRestoreFile(
          imageDirectory,
          record.id,
          entry.extension,
        );
        await destination.writeAsBytes(bytes, flush: true);
        stagedFiles.add(destination);
        restoredImages.add(record.copyWith(path: destination.path));
      }

      await database.transaction(() async {
        await database.batch((batch) {
          batch.deleteAll(database.photoAlignments);
          batch.deleteAll(database.shotImpacts);
          batch.deleteAll(database.imageAssets);
          batch.deleteAll(database.shootingSeries);
          batch.deleteAll(database.trainingSessions);
          batch.deleteAll(database.goals);
          batch.deleteAll(database.ammoLots);
          batch.deleteAll(database.firearms);
          batch.deleteAll(database.ranges);
          batch.deleteAll(database.targetProfiles);
          batch.deleteAll(database.cartridges);
          batch.deleteAll(database.preferences);

          batch.insertAll(database.cartridges, cartridges);
          batch.insertAll(database.ranges, ranges);
          batch.insertAll(database.firearms, firearms);
          batch.insertAll(database.ammoLots, ammoLots);
          batch.insertAll(database.targetProfiles, targetProfiles);
          batch.insertAll(database.trainingSessions, sessions);
          batch.insertAll(database.shootingSeries, series);
          batch.insertAll(database.imageAssets, restoredImages);
          batch.insertAll(database.shotImpacts, impacts);
          batch.insertAll(database.photoAlignments, alignments);
          batch.insertAll(database.goals, goals);
          batch.insertAll(database.preferences, settings);
        });
      });
    } catch (_) {
      for (final staged in stagedFiles) {
        try {
          if (await staged.exists()) await staged.delete();
        } on FileSystemException {
          // The database transaction is still rolled back. Cleanup can be
          // retried by storage diagnostics without hiding the original error.
        }
      }
      rethrow;
    }

    final restoredPaths = restoredImages
        .map((item) => path.normalize(path.absolute(item.path)))
        .toSet();
    final ownedRoot = path.normalize(
      path.absolute(path.join(appRoot.path, 'target_images')),
    );
    for (final image in oldImages) {
      final normalized = path.normalize(path.absolute(image.path));
      if (restoredPaths.contains(normalized) ||
          !(normalized == ownedRoot || path.isWithin(ownedRoot, normalized))) {
        continue;
      }
      try {
        final oldFile = File(normalized);
        if (await oldFile.exists()) await oldFile.delete();
      } on FileSystemException {
        // Records have already been restored successfully. A stale private
        // file is safer than rolling back a successful logical restore.
      }
    }
    return RestoreResult(summary: payload.summary, safetyBackup: safetyBackup);
  }

  Future<Archive> _createArchive() async {
    final sessions = await database.select(database.trainingSessions).get();
    final series = await database.select(database.shootingSeries).get();
    final impacts = await database.select(database.shotImpacts).get();
    final firearms = await database.select(database.firearms).get();
    final cartridges = await database.select(database.cartridges).get();
    final ammoLots = await database.select(database.ammoLots).get();
    final ranges = await database.select(database.ranges).get();
    final images = await database.select(database.imageAssets).get();
    final alignments = await database.select(database.photoAlignments).get();
    final goals = await database.select(database.goals).get();
    final settings = await database.select(database.preferences).get();
    final targetProfiles = await database.select(database.targetProfiles).get();
    final createdAt = _now().toUtc();
    final archive = Archive();
    final files = <Map<String, dynamic>>[];

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final file = File(image.path);
      if (!await file.exists()) {
        throw StateError('Fotobestand ${image.id} bestaat niet meer.');
      }
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != image.sha256 || bytes.length != image.sizeBytes) {
        throw StateError('Fotobestand ${image.id} is gewijzigd of beschadigd.');
      }
      final extension = _safeExtension(file.path);
      final archivePath =
          'media/${index.toString().padLeft(6, '0')}-${_safeFilePart(image.id)}$extension';
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
      files.add({
        'imageId': image.id,
        'archivePath': archivePath,
        'sha256': digest,
        'sizeBytes': bytes.length,
      });
    }

    archive.addFile(
      ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'format': 'shooting-companion-backup',
          'formatVersion': BackupPayloadAdapter.currentFormatVersion,
          'appVersion': '0.3.0',
          'databaseSchemaVersion': 3,
          'minimumAppVersion': '0.2.0',
          'createdAtUtc': createdAt.toIso8601String(),
          'sessionCount': sessions.length,
          'seriesCount': series.length,
          'imageCount': images.length,
          'files': files,
        }),
      ),
    );
    archive.addFile(
      ArchiveFile.string(
        'database.json',
        jsonEncode({
          'sessions': sessions.map((row) => row.toJson()).toList(),
          'series': series.map((row) => row.toJson()).toList(),
          'impacts': impacts.map((row) => row.toJson()).toList(),
          'firearms': firearms.map((row) => row.toJson()).toList(),
          'cartridges': cartridges.map((row) => row.toJson()).toList(),
          'ammoLots': ammoLots.map((row) => row.toJson()).toList(),
          'ranges': ranges.map((row) => row.toJson()).toList(),
          'images': images.map((row) => row.toJson()).toList(),
          'photoAlignments': alignments.map((row) => row.toJson()).toList(),
          'goals': goals.map((row) => row.toJson()).toList(),
          'settings': settings.map((row) => row.toJson()).toList(),
          'targetProfiles': targetProfiles.map((row) => row.toJson()).toList(),
        }),
      ),
    );
    return archive;
  }

  NormalizedBackupPayload _readPayload(Archive archive) {
    final manifestFile = archive.findFile('manifest.json');
    final databaseFile = archive.findFile('database.json');
    if (manifestFile == null || databaseFile == null) {
      throw const FormatException('Manifest of databasebestand ontbreekt.');
    }
    return BackupPayloadAdapter.normalize(
      manifest: _jsonObject(manifestFile, 'manifest.json'),
      data: _jsonObject(databaseFile, 'database.json'),
    );
  }

  Map<String, _BackupMediaEntry> _mediaEntries(
    NormalizedBackupPayload payload,
    List<ImageAssetRecord> images,
  ) {
    if (payload.sourceFormatVersion == 1) {
      return {
        for (final image in images)
          image.id: _BackupMediaEntry(
            archivePath: 'images/${image.id}.jpg',
            sha256: image.sha256,
            sizeBytes: image.sizeBytes,
            extension: '.jpg',
          ),
      };
    }
    final rawFiles = payload.manifest['files'];
    if (rawFiles is! List) {
      throw const FormatException('Bestandsmanifest ontbreekt.');
    }
    final result = <String, _BackupMediaEntry>{};
    for (final value in rawFiles) {
      if (value is! Map) {
        throw const FormatException('Ongeldige bestandsbeschrijving.');
      }
      final item = value.cast<String, dynamic>();
      final imageId = item['imageId'];
      final archivePath = item['archivePath'];
      final digest = item['sha256'];
      final size = item['sizeBytes'];
      if (imageId is! String ||
          archivePath is! String ||
          digest is! String ||
          size is! int ||
          result.containsKey(imageId) ||
          !_isSafeArchiveMediaPath(archivePath)) {
        throw const FormatException('Ongeldige bestandsbeschrijving.');
      }
      result[imageId] = _BackupMediaEntry(
        archivePath: archivePath,
        sha256: digest,
        sizeBytes: size,
        extension: _safeExtension(archivePath),
      );
    }
    if (result.length != images.length) {
      throw const FormatException(
        'Aantal bestanden komt niet overeen met het fotoregister.',
      );
    }
    return result;
  }

  Future<Archive> _decryptArchive(Uint8List bytes, String password) async {
    final minimum = _magic.length + _saltLength + _nonceLength + _macLength;
    if (bytes.length <= minimum || !_startsWith(bytes, _magic)) {
      throw const FormatException(
        'Geen geldig Shooting Companion-back-upbestand.',
      );
    }
    var offset = _magic.length;
    final salt = bytes.sublist(offset, offset += _saltLength);
    final nonce = bytes.sublist(offset, offset += _nonceLength);
    final mac = bytes.sublist(offset, offset += _macLength);
    final cipherText = bytes.sublist(offset);
    final key = await _deriveKey(password, salt);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
      return ZipDecoder().decodeBytes(clear, verify: true);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Onjuist wachtwoord of beschadigde back-up.');
    } on ArchiveException {
      throw const FormatException('Back-uparchief is beschadigd.');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Argon2id(
    parallelism: 1,
    memory: 19 * 1024,
    iterations: 2,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  bool _startsWith(List<int> bytes, List<int> prefix) {
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[index] != prefix[index]) return false;
    }
    return true;
  }

  List<T> _rows<T>(
    Map<String, dynamic> data,
    String key,
    T Function(Map<String, dynamic>) decoder,
  ) => (data[key]! as List)
      .map((row) => decoder((row as Map).cast<String, dynamic>()))
      .toList();

  Map<String, dynamic> _jsonObject(ArchiveFile file, String label) {
    try {
      final decoded = jsonDecode(utf8.decode(file.content as List<int>));
      if (decoded is! Map) throw const FormatException();
      return decoded.cast<String, dynamic>();
    } on FormatException {
      throw FormatException('$label bevat geen geldige JSON.');
    }
  }

  Future<File> _uniqueRestoreFile(
    Directory directory,
    String imageId,
    String extension,
  ) async {
    final stem =
        'restore-${_now().toUtc().microsecondsSinceEpoch}-${_safeFilePart(imageId)}';
    var suffix = 0;
    while (true) {
      final name = suffix == 0 ? '$stem$extension' : '$stem-$suffix$extension';
      final candidate = File(path.join(directory.path, name));
      if (!await candidate.exists()) return candidate;
      suffix++;
    }
  }

  static bool _isSafeArchiveMediaPath(String value) {
    final normalized = path.posix.normalize(value.replaceAll('\\', '/'));
    return normalized.startsWith('media/') &&
        !normalized.startsWith('/') &&
        !normalized.contains('../');
  }

  static String _safeFilePart(String value) {
    final safe = value.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');
    return safe.isEmpty ? 'image' : safe;
  }

  static String _safeExtension(String value) {
    final extension = path.extension(value).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)
        ? extension
        : '.jpg';
  }
}

class _BackupMediaEntry {
  const _BackupMediaEntry({
    required this.archivePath,
    required this.sha256,
    required this.sizeBytes,
    required this.extension,
  });

  final String archivePath;
  final String sha256;
  final int? sizeBytes;
  final String extension;
}
