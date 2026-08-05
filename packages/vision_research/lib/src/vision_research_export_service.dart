import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:image/image.dart' as image;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import 'models.dart';

typedef VisionRandomBytesProvider = Uint8List Function(int length);

class VisionResearchExportService {
  VisionResearchExportService({
    this.limits = const VisionResearchLimits(),
    DateTime Function()? now,
    VisionRandomBytesProvider? randomBytes,
  }) : _now = now ?? DateTime.now,
       _randomBytes = randomBytes ?? _secureRandomBytes;

  static const _outerMagic = [0x53, 0x43, 0x56, 0x31]; // SCV1
  static const _innerMagic = [0x53, 0x56, 0x50, 0x31]; // SVP1
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _lengthFieldBytes = 4;
  static const _format = 'shooting-companion-vision-research';
  static const _formatVersion = 1;
  static const _privacyProfile = 'strict-crop-only-v1';

  final VisionResearchLimits limits;
  final DateTime Function() _now;
  final VisionRandomBytesProvider _randomBytes;

  Future<Uint8List> createEncryptedExport(
    VisionResearchExportRequest request,
    String password,
  ) async {
    _validatePassword(password);
    _validateRequest(request);
    final crop = _sanitizeCrop(
      request.croppedTargetBytes,
      request.cropMediaType,
    );
    final impacts = [
      for (
        var index = 0;
        index < request.confirmedManualImpacts.length;
        index++
      )
        VisionResearchImpact.fromConfirmedManualShot(
          request.confirmedManualImpacts[index],
          index + 1,
        ),
    ];
    final decoded = VisionResearchDecodedExport(
      croppedTargetBytes: crop.bytes,
      cropMediaType: request.cropMediaType,
      targetProfileSnapshot: VisionTargetProfileSnapshot.fromTargetProfile(
        request.targetProfileSnapshot,
      ),
      projectileDiameterMm: request.projectileDiameterMm,
      impacts: impacts,
      alignment: request.alignment,
      qualityLabels: request.qualityLabels,
      consent: request.consent,
    );
    final recordsBytes = _canonicalJsonBytes(
      decoded.toPrivacySafeRecordsJson(),
    );
    if (recordsBytes.length > limits.maximumMetadataBytes) {
      throw const FormatException('Onderzoeksmetadata is te groot.');
    }
    final createdAt = _now().toUtc();
    final cropName = 'target-crop.${request.cropMediaType.extension}';
    final manifest = <String, Object?>{
      'createdAtUtc': createdAt.toIso8601String(),
      'entries': [
        {
          'mediaType': 'application/json',
          'name': 'records.json',
          'sha256': sha256.convert(recordsBytes).toString(),
          'sizeBytes': recordsBytes.length,
        },
        {
          'mediaType': request.cropMediaType.mimeType,
          'name': cropName,
          'sha256': sha256.convert(crop.bytes).toString(),
          'sizeBytes': crop.bytes.length,
        },
      ],
      'format': _format,
      'formatVersion': _formatVersion,
      'imageHeight': crop.height,
      'imageWidth': crop.width,
      'impactCount': impacts.length,
      'privacyProfile': _privacyProfile,
      'profileVersionedId': request.targetProfileSnapshot.versionedId,
    };
    final manifestBytes = _canonicalJsonBytes(manifest);
    if (manifestBytes.length > limits.maximumMetadataBytes) {
      throw const FormatException('Onderzoeksmanifest is te groot.');
    }
    final clear = _encodeClearPayload(
      manifestBytes: manifestBytes,
      recordsBytes: recordsBytes,
      cropBytes: crop.bytes,
    );
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    if (salt.length != _saltLength || nonce.length != _nonceLength) {
      throw StateError(
        'De veilige toevalsgenerator leverde een ongeldige lengte.',
      );
    }
    final key = await _deriveKey(password, salt);
    final secretBox = await AesGcm.with256bits().encrypt(
      clear,
      secretKey: key,
      nonce: nonce,
    );
    final result = Uint8List.fromList([
      ..._outerMagic,
      ...salt,
      ...nonce,
      ...secretBox.mac.bytes,
      ...secretBox.cipherText,
    ]);
    if (result.length > limits.maximumContainerBytes) {
      throw const FormatException('Versleutelde onderzoeksexport is te groot.');
    }
    return result;
  }

  /// Writes in bounded chunks and refuses to overwrite an existing export.
  Future<File> writeEncryptedExport({
    required File destination,
    required VisionResearchExportRequest request,
    required String password,
  }) async {
    if (!destination.path.toLowerCase().endsWith('.scvision')) {
      throw const FormatException('Een onderzoeksexport moet .scvision heten.');
    }
    final bytes = await createEncryptedExport(request, password);
    await destination.parent.create(recursive: true);
    RandomAccessFile? writer;
    var created = false;
    try {
      await destination.create(exclusive: true);
      created = true;
      writer = await destination.open(mode: FileMode.writeOnly);
      const chunkSize = 64 * 1024;
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = min(offset + chunkSize, bytes.length);
        await writer.writeFrom(bytes, offset, end);
      }
      await writer.flush();
      await writer.close();
      writer = null;
      return destination;
    } catch (_) {
      await writer?.close();
      if (created) {
        try {
          if (await destination.exists()) await destination.delete();
        } on FileSystemException {
          // Do not hide the original write failure.
        }
      }
      rethrow;
    }
  }

  Future<VisionResearchInspection> inspectEncryptedFile(
    File file,
    String password,
  ) async {
    final length = await file.length();
    if (length > limits.maximumContainerBytes) {
      throw const FormatException('Onderzoeksexport overschrijdt de limiet.');
    }
    return inspectEncryptedBytes(await file.readAsBytes(), password);
  }

  Future<VisionResearchInspection> inspectEncryptedBytes(
    Uint8List bytes,
    String password,
  ) async {
    final parsed = await _decryptAndValidate(bytes, password);
    return parsed.inspection;
  }

  Future<VisionResearchDecodedExport> readEncryptedFile(
    File file,
    String password,
  ) async {
    final length = await file.length();
    if (length > limits.maximumContainerBytes) {
      throw const FormatException('Onderzoeksexport overschrijdt de limiet.');
    }
    return readEncryptedBytes(await file.readAsBytes(), password);
  }

  Future<VisionResearchDecodedExport> readEncryptedBytes(
    Uint8List bytes,
    String password,
  ) async {
    final parsed = await _decryptAndValidate(bytes, password);
    return parsed.decoded;
  }

  Future<_ParsedExport> _decryptAndValidate(
    Uint8List bytes,
    String password,
  ) async {
    _validatePassword(password);
    final minimum =
        _outerMagic.length + _saltLength + _nonceLength + _macLength + 1;
    if (bytes.length < minimum ||
        bytes.length > limits.maximumContainerBytes ||
        !_startsWith(bytes, _outerMagic)) {
      throw const FormatException('Geen geldige .scvision-container.');
    }
    var offset = _outerMagic.length;
    final salt = bytes.sublist(offset, offset += _saltLength);
    final nonce = bytes.sublist(offset, offset += _nonceLength);
    final mac = bytes.sublist(offset, offset += _macLength);
    final cipherText = bytes.sublist(offset);
    final key = await _deriveKey(password, salt);
    late final List<int> clear;
    try {
      clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      throw const FormatException(
        'Onjuist wachtwoord of beschadigde onderzoeksexport.',
      );
    }
    try {
      return _decodeAndValidateClear(Uint8List.fromList(clear));
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Ongeldige onderzoekspayload.', error);
    }
  }

  _ParsedExport _decodeAndValidateClear(Uint8List clear) {
    const headerLength = 4 + (_lengthFieldBytes * 2);
    if (clear.length < headerLength || !_startsWith(clear, _innerMagic)) {
      throw const FormatException('Ongeldige interne onderzoekspayload.');
    }
    final manifestLength = _readUint32(clear, 4);
    final recordsLength = _readUint32(clear, 8);
    if (manifestLength <= 0 ||
        recordsLength <= 0 ||
        manifestLength > limits.maximumMetadataBytes ||
        recordsLength > limits.maximumMetadataBytes) {
      throw const FormatException('Ongeldige metadatalengte.');
    }
    final cropOffset = headerLength + manifestLength + recordsLength;
    if (cropOffset >= clear.length ||
        clear.length - cropOffset > limits.maximumSanitizedCropBytes) {
      throw const FormatException('Ongeldige kaartcropgrootte.');
    }
    final manifestBytes = clear.sublist(
      headerLength,
      headerLength + manifestLength,
    );
    final recordsBytes = clear.sublist(
      headerLength + manifestLength,
      cropOffset,
    );
    final cropBytes = clear.sublist(cropOffset);
    final manifest = _readCanonicalObject(manifestBytes, 'manifest');
    final records = _readCanonicalObject(recordsBytes, 'records');
    final parsedManifest = _validateManifest(manifest);
    _verifyEntry(
      parsedManifest.recordsEntry,
      expectedName: 'records.json',
      expectedMediaType: 'application/json',
      bytes: recordsBytes,
    );
    final cropMediaType = VisionCropMediaType.values.firstWhere(
      (type) => type.mimeType == parsedManifest.cropEntry.mediaType,
      orElse: () => throw const FormatException('Onbekend kaartcropformaat.'),
    );
    _verifyEntry(
      parsedManifest.cropEntry,
      expectedName: 'target-crop.${cropMediaType.extension}',
      expectedMediaType: cropMediaType.mimeType,
      bytes: cropBytes,
    );
    final crop = _validateSanitizedCrop(cropBytes, cropMediaType);
    if (crop.width != parsedManifest.imageWidth ||
        crop.height != parsedManifest.imageHeight) {
      throw const FormatException('Afmetingen van de kaartcrop kloppen niet.');
    }
    final decoded = _decodeRecords(records, cropBytes, cropMediaType);
    if (decoded.targetProfileSnapshot.versionedId !=
            parsedManifest.profileVersionedId ||
        decoded.impacts.length != parsedManifest.impactCount) {
      throw const FormatException('Manifest en onderzoeksrecords verschillen.');
    }
    _validateDecoded(decoded);
    final rebuiltRecords = _canonicalJsonBytes(
      decoded.toPrivacySafeRecordsJson(),
    );
    if (!_bytesEqual(rebuiltRecords, recordsBytes)) {
      throw const FormatException(
        'Onderzoeksrecords zijn niet canoniek of bevatten extra velden.',
      );
    }
    final inspection = VisionResearchInspection(
      createdAtUtc: parsedManifest.createdAtUtc,
      profileVersionedId: parsedManifest.profileVersionedId,
      projectileDiameterMm: decoded.projectileDiameterMm,
      impactCount: decoded.impacts.length,
      cropMediaType: cropMediaType,
      cropSizeBytes: cropBytes.length,
      cropSha256: sha256.convert(cropBytes).toString(),
      imageWidth: crop.width,
      imageHeight: crop.height,
      manifestSha256: sha256.convert(manifestBytes).toString(),
      qualityLabels: decoded.qualityLabels,
      consent: decoded.consent,
    );
    return _ParsedExport(decoded: decoded, inspection: inspection);
  }

  VisionResearchDecodedExport _decodeRecords(
    Map<String, Object?> records,
    Uint8List cropBytes,
    VisionCropMediaType cropMediaType,
  ) {
    const keys = {
      'alignment',
      'consent',
      'impacts',
      'projectileDiameterMm',
      'qualityLabels',
      'targetProfileSnapshot',
    };
    _expectExactKeys(records, keys, 'onderzoeksrecords');
    final rawImpacts = records['impacts'];
    final rawLabels = records['qualityLabels'];
    if (rawImpacts is! List || rawLabels is! List) {
      throw const FormatException('Ongeldige treffers of kwaliteitslabels.');
    }
    final impacts = [
      for (final raw in rawImpacts)
        VisionResearchImpact.fromJson(_object(raw, 'treffer')),
    ];
    final labels = <VisionQualityLabel>{};
    for (final raw in rawLabels) {
      if (raw is! String) {
        throw const FormatException('Ongeldig kwaliteitslabel.');
      }
      try {
        labels.add(VisionQualityLabel.values.byName(raw));
      } on ArgumentError {
        throw FormatException('Onbekend kwaliteitslabel: $raw.');
      }
    }
    return VisionResearchDecodedExport(
      croppedTargetBytes: cropBytes,
      cropMediaType: cropMediaType,
      targetProfileSnapshot: VisionTargetProfileSnapshot.fromJson(
        _object(records['targetProfileSnapshot'], 'doelprofiel'),
      ),
      projectileDiameterMm: (records['projectileDiameterMm']! as num)
          .toDouble(),
      impacts: impacts,
      alignment: ManualPhotoAlignment.fromJson(
        _object(records['alignment'], 'uitlijning'),
      ),
      qualityLabels: labels,
      consent: VisionResearchConsent.fromJson(
        _object(records['consent'], 'consentmanifest'),
      ),
    );
  }

  _ParsedManifest _validateManifest(Map<String, Object?> manifest) {
    const keys = {
      'createdAtUtc',
      'entries',
      'format',
      'formatVersion',
      'imageHeight',
      'imageWidth',
      'impactCount',
      'privacyProfile',
      'profileVersionedId',
    };
    _expectExactKeys(manifest, keys, 'manifest');
    if (manifest['format'] != _format ||
        manifest['formatVersion'] != _formatVersion ||
        manifest['privacyProfile'] != _privacyProfile) {
      throw const FormatException('Niet-ondersteund onderzoeksmanifest.');
    }
    final createdAt = DateTime.tryParse(
      manifest['createdAtUtc'] as String? ?? '',
    );
    final entries = manifest['entries'];
    if (createdAt == null ||
        !createdAt.isUtc ||
        entries is! List ||
        entries.length != 2) {
      throw const FormatException('Ongeldige manifestmetadata.');
    }
    final parsedEntries = entries
        .map((raw) => _ManifestEntry.fromJson(_object(raw, 'bestandsrecord')))
        .toList();
    if (parsedEntries[0].name != 'records.json' ||
        !parsedEntries[1].name.startsWith('target-crop.')) {
      throw const FormatException('Bestandsrecords staan niet canoniek.');
    }
    final imageWidth = manifest['imageWidth'];
    final imageHeight = manifest['imageHeight'];
    final impactCount = manifest['impactCount'];
    final profileVersionedId = manifest['profileVersionedId'];
    if (imageWidth is! int ||
        imageHeight is! int ||
        imageWidth <= 0 ||
        imageHeight <= 0 ||
        impactCount is! int ||
        impactCount < 0 ||
        profileVersionedId is! String ||
        profileVersionedId.isEmpty) {
      throw const FormatException('Ongeldige manifestwaarden.');
    }
    return _ParsedManifest(
      createdAtUtc: createdAt,
      profileVersionedId: profileVersionedId,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      impactCount: impactCount,
      recordsEntry: parsedEntries[0],
      cropEntry: parsedEntries[1],
    );
  }

  void _validateRequest(VisionResearchExportRequest request) {
    if (request.croppedTargetBytes.isEmpty ||
        request.croppedTargetBytes.length > limits.maximumInputCropBytes) {
      throw const FormatException('Kaartcrop ontbreekt of is te groot.');
    }
    if (!request.projectileDiameterMm.isFinite ||
        request.projectileDiameterMm <= 0 ||
        request.projectileDiameterMm > 25) {
      throw const FormatException('Ongeldige projectieldiameter.');
    }
    if (request.confirmedManualImpacts.length > limits.maximumImpacts) {
      throw const FormatException(
        'Te veel treffers voor een onderzoeksexport.',
      );
    }
    request.consent.validate();
    _validateQualityLabels(request.qualityLabels);
    if ((request.alignment.cardWidthMm -
                    request.targetProfileSnapshot.physicalCardWidthMm)
                .abs() >
            0.001 ||
        (request.alignment.cardHeightMm -
                    request.targetProfileSnapshot.physicalCardHeightMm)
                .abs() >
            0.001) {
      throw const FormatException(
        'Uitlijning en gekozen doelprofiel hebben andere afmetingen.',
      );
    }
    final validBullIds = request.targetProfileSnapshot.bulls
        .map((bull) => bull.id)
        .toSet();
    for (
      var index = 0;
      index < request.confirmedManualImpacts.length;
      index++
    ) {
      final impact = VisionResearchImpact.fromConfirmedManualShot(
        request.confirmedManualImpacts[index],
        index + 1,
      );
      impact.validate();
      if (impact.targetBullId != null &&
          !validBullIds.contains(impact.targetBullId)) {
        throw const FormatException(
          'Treffer verwijst naar een onbekend roosje.',
        );
      }
    }
  }

  void _validateDecoded(VisionResearchDecodedExport decoded) {
    if (!decoded.projectileDiameterMm.isFinite ||
        decoded.projectileDiameterMm <= 0 ||
        decoded.projectileDiameterMm > 25 ||
        decoded.impacts.length > limits.maximumImpacts) {
      throw const FormatException('Ongeldige onderzoeksrecords.');
    }
    decoded.consent.validate();
    _validateQualityLabels(decoded.qualityLabels);
    if ((decoded.alignment.cardWidthMm -
                    decoded.targetProfileSnapshot.physicalCardWidthMm)
                .abs() >
            0.001 ||
        (decoded.alignment.cardHeightMm -
                    decoded.targetProfileSnapshot.physicalCardHeightMm)
                .abs() >
            0.001) {
      throw const FormatException('Uitlijning past niet bij het doelprofiel.');
    }
    final bullIds = decoded.targetProfileSnapshot.bulls
        .map((bull) => bull.id)
        .toSet();
    for (var index = 0; index < decoded.impacts.length; index++) {
      final impact = decoded.impacts[index];
      impact.validate();
      if (impact.ordinal != index + 1 ||
          (impact.targetBullId != null &&
              !bullIds.contains(impact.targetBullId))) {
        throw const FormatException(
          'Ongeldige treffervolgorde of roosverwijzing.',
        );
      }
    }
  }

  void _validateQualityLabels(Set<VisionQualityLabel> labels) {
    if (labels.isEmpty) {
      throw const FormatException('Minstens een kwaliteitslabel is vereist.');
    }
    if (labels.contains(VisionQualityLabel.unreviewed) && labels.length > 1) {
      throw const FormatException(
        'Niet beoordeeld kan niet met andere kwaliteitslabels worden gecombineerd.',
      );
    }
  }

  _SanitizedCrop _sanitizeCrop(Uint8List bytes, VisionCropMediaType mediaType) {
    final decoded = _decodeCrop(bytes, mediaType);
    decoded.exif = image.ExifData();
    decoded.textData = null;
    decoded.iccProfile = null;
    final sanitized = switch (mediaType) {
      VisionCropMediaType.jpeg => image.encodeJpg(decoded, quality: 95),
      VisionCropMediaType.png => image.encodePng(decoded),
    };
    if (sanitized.length > limits.maximumSanitizedCropBytes) {
      throw const FormatException('Opgeschoonde kaartcrop is te groot.');
    }
    _rejectMetadata(sanitized, mediaType);
    return _SanitizedCrop(
      bytes: sanitized,
      width: decoded.width,
      height: decoded.height,
    );
  }

  _SanitizedCrop _validateSanitizedCrop(
    Uint8List bytes,
    VisionCropMediaType mediaType,
  ) {
    _rejectMetadata(bytes, mediaType);
    final decoded = _decodeCrop(bytes, mediaType);
    if (!decoded.exif.isEmpty ||
        (decoded.textData?.isNotEmpty ?? false) ||
        decoded.iccProfile != null) {
      throw const FormatException('Kaartcrop bevat verboden metadata.');
    }
    return _SanitizedCrop(
      bytes: bytes,
      width: decoded.width,
      height: decoded.height,
    );
  }

  image.Image _decodeCrop(Uint8List bytes, VisionCropMediaType mediaType) {
    final decoder = switch (mediaType) {
      VisionCropMediaType.jpeg => image.JpegDecoder(),
      VisionCropMediaType.png => image.PngDecoder(),
    };
    final info = decoder.startDecode(bytes);
    if (info == null ||
        info.width < 16 ||
        info.height < 16 ||
        info.numFrames != 1 ||
        info.width * info.height > limits.maximumImagePixels) {
      throw const FormatException('Ongeldige of onveilige kaartcrop.');
    }
    final decoded = decoder.decodeFrame(0);
    if (decoded == null) {
      throw const FormatException('Kaartcrop kan niet worden gelezen.');
    }
    return decoded;
  }

  void _rejectMetadata(Uint8List bytes, VisionCropMediaType mediaType) {
    switch (mediaType) {
      case VisionCropMediaType.jpeg:
        _rejectJpegMetadata(bytes);
      case VisionCropMediaType.png:
        _rejectPngMetadata(bytes);
    }
  }

  void _rejectJpegMetadata(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      throw const FormatException('Kaartcrop is geen geldige JPEG.');
    }
    var offset = 2;
    while (offset + 3 < bytes.length) {
      if (bytes[offset] != 0xff) {
        offset++;
        continue;
      }
      final marker = bytes[offset + 1];
      if (marker == 0xda || marker == 0xd9) return;
      if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) {
        offset += 2;
        continue;
      }
      if (offset + 4 > bytes.length) {
        throw const FormatException('Beschadigde JPEG-marker.');
      }
      final segmentLength = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (segmentLength < 2 || offset + 2 + segmentLength > bytes.length) {
        throw const FormatException('Beschadigde JPEG-sectie.');
      }
      if (marker == 0xe1 || marker == 0xed || marker == 0xfe) {
        throw const FormatException(
          'JPEG bevat EXIF, tekst of andere metadata.',
        );
      }
      offset += 2 + segmentLength;
    }
  }

  void _rejectPngMetadata(Uint8List bytes) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length || !_startsWith(bytes, signature)) {
      throw const FormatException('Kaartcrop is geen geldige PNG.');
    }
    var offset = signature.length;
    while (offset + 12 <= bytes.length) {
      final length = _readUint32(bytes, offset);
      final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
      final end = offset + 12 + length;
      if (length < 0 || end > bytes.length) {
        throw const FormatException('Beschadigde PNG-sectie.');
      }
      if (const {'eXIf', 'tEXt', 'zTXt', 'iTXt'}.contains(type)) {
        throw const FormatException('PNG bevat EXIF of tekstmetadata.');
      }
      offset = end;
      if (type == 'IEND') return;
    }
    throw const FormatException('PNG mist een geldige afsluiting.');
  }

  Uint8List _encodeClearPayload({
    required Uint8List manifestBytes,
    required Uint8List recordsBytes,
    required Uint8List cropBytes,
  }) {
    final result = BytesBuilder(copy: false)
      ..add(_innerMagic)
      ..add(_uint32(manifestBytes.length))
      ..add(_uint32(recordsBytes.length))
      ..add(manifestBytes)
      ..add(recordsBytes)
      ..add(cropBytes);
    return result.takeBytes();
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Argon2id(
    parallelism: 1,
    memory: 19 * 1024,
    iterations: 2,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  void _validatePassword(String password) {
    if (password.length < 10 || password.length > 1024) {
      throw const FormatException(
        'Gebruik een wachtwoord van 10 tot en met 1024 tekens.',
      );
    }
  }
}

class _ParsedExport {
  const _ParsedExport({required this.decoded, required this.inspection});

  final VisionResearchDecodedExport decoded;
  final VisionResearchInspection inspection;
}

class _ParsedManifest {
  const _ParsedManifest({
    required this.createdAtUtc,
    required this.profileVersionedId,
    required this.imageWidth,
    required this.imageHeight,
    required this.impactCount,
    required this.recordsEntry,
    required this.cropEntry,
  });

  final DateTime createdAtUtc;
  final String profileVersionedId;
  final int imageWidth;
  final int imageHeight;
  final int impactCount;
  final _ManifestEntry recordsEntry;
  final _ManifestEntry cropEntry;
}

class _ManifestEntry {
  const _ManifestEntry({
    required this.name,
    required this.mediaType,
    required this.sha256,
    required this.sizeBytes,
  });

  final String name;
  final String mediaType;
  final String sha256;
  final int sizeBytes;

  factory _ManifestEntry.fromJson(Map<String, Object?> json) {
    _expectExactKeys(json, const {
      'mediaType',
      'name',
      'sha256',
      'sizeBytes',
    }, 'bestandsrecord');
    final name = json['name'];
    final mediaType = json['mediaType'];
    final digest = json['sha256'];
    final size = json['sizeBytes'];
    if (name is! String ||
        mediaType is! String ||
        digest is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
        size is! int ||
        size <= 0) {
      throw const FormatException('Ongeldig bestandsrecord.');
    }
    return _ManifestEntry(
      name: name,
      mediaType: mediaType,
      sha256: digest,
      sizeBytes: size,
    );
  }
}

class _SanitizedCrop {
  const _SanitizedCrop({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

void _verifyEntry(
  _ManifestEntry entry, {
  required String expectedName,
  required String expectedMediaType,
  required List<int> bytes,
}) {
  if (entry.name != expectedName ||
      entry.mediaType != expectedMediaType ||
      entry.sizeBytes != bytes.length ||
      entry.sha256 != sha256.convert(bytes).toString()) {
    throw FormatException(
      'Integriteitscontrole voor $expectedName is mislukt.',
    );
  }
}

Map<String, Object?> _readCanonicalObject(Uint8List bytes, String label) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw FormatException('$label bevat ongeldige JSON.');
  }
  if (decoded is! Map) {
    throw FormatException('$label moet een JSON-object zijn.');
  }
  final object = decoded.cast<String, Object?>();
  if (!_bytesEqual(_canonicalJsonBytes(object), bytes)) {
    throw FormatException('$label is niet canoniek geserialiseerd.');
  }
  return object;
}

Uint8List _canonicalJsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(_canonicalize(value))));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final result = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('JSON-sleutels moeten tekst zijn.');
      }
      result[entry.key! as String] = _canonicalize(entry.value);
    }
    return result;
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value is num && !value.isFinite) {
    throw const FormatException('Niet-eindige getallen zijn niet toegestaan.');
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw FormatException('Niet-ondersteunde JSON-waarde: ${value.runtimeType}.');
}

Map<String, Object?> _object(Object? value, String label) {
  if (value is! Map) throw FormatException('$label moet een object zijn.');
  return value.cast<String, Object?>();
}

void _expectExactKeys(
  Map<String, Object?> json,
  Set<String> expected,
  String label,
) {
  final actual = json.keys.toSet();
  if (actual.difference(expected).isNotEmpty ||
      expected.difference(actual).isNotEmpty) {
    throw FormatException('$label bevat onverwachte of ontbrekende velden.');
  }
}

Uint8List _uint32(int value) {
  if (value < 0 || value > 0xffffffff) {
    throw RangeError.range(value, 0, 0xffffffff);
  }
  final data = ByteData(4)..setUint32(0, value, Endian.big);
  return data.buffer.asUint8List();
}

int _readUint32(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 4 > bytes.length) {
    throw const FormatException('Onvolledig lengteveld.');
  }
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 4,
  ).getUint32(0, Endian.big);
}

bool _startsWith(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

bool _bytesEqual(List<int> first, List<int> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

Uint8List _secureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256), growable: false),
  );
}
