import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class StoredImage {
  const StoredImage({
    required this.path,
    required this.sha256,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  final String path;
  final String sha256;
  final int width;
  final int height;
  final int sizeBytes;
}

class StagedImage {
  const StagedImage({
    required this.path,
    required this.sha256,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  final String path;
  final String sha256;
  final int width;
  final int height;
  final int sizeBytes;
}

/// Centralizes every path owned by the photo store.
///
/// This class has no Flutter dependency and can be tested with a temporary
/// directory. It also provides the containment checks used before deletion.
class ImageStoragePaths {
  ImageStoragePaths(String applicationDocumentsPath)
    : applicationDocumentsPath = path.normalize(
        path.absolute(applicationDocumentsPath),
      );

  final String applicationDocumentsPath;

  String get root => path.join(applicationDocumentsPath, 'target_images');

  String get staging => path.join(root, 'staging');

  String get originals => path.join(root, 'originals');

  bool owns(String candidatePath) {
    final normalized = path.normalize(path.absolute(candidatePath));
    return _samePath(normalized, root) || path.isWithin(root, normalized);
  }

  bool isStaged(String candidatePath) {
    final normalized = path.normalize(path.absolute(candidatePath));
    return path.isWithin(staging, normalized);
  }

  bool isOriginal(String candidatePath) {
    final normalized = path.normalize(path.absolute(candidatePath));
    return path.isWithin(originals, normalized);
  }

  bool _samePath(String first, String second) => Platform.isWindows
      ? first.toLowerCase() == second.toLowerCase()
      : first == second;
}

class ImageStorageService {
  ImageStorageService({
    Future<Directory> Function()? applicationDocumentsDirectory,
    DateTime Function()? now,
    String Function()? tokenFactory,
  }) : _applicationDocumentsDirectory =
           applicationDocumentsDirectory ?? getApplicationDocumentsDirectory,
       _now = now ?? DateTime.now,
       _tokenFactory = tokenFactory ?? _randomToken;

  final Future<Directory> Function() _applicationDocumentsDirectory;
  final DateTime Function() _now;
  final String Function() _tokenFactory;

  /// Backwards-compatible one-step import implemented through staging.
  Future<StoredImage> importJpeg(String sourcePath) async {
    final staged = await stageJpeg(sourcePath);
    try {
      return await finalizeStagedImage(staged);
    } catch (_) {
      await discardStagedImage(staged);
      rethrow;
    }
  }

  /// Decodes, applies EXIF orientation and re-encodes an image without EXIF.
  ///
  /// The result lives in the staging directory until the repository has enough
  /// information to attach it to a session or series.
  Future<StagedImage> stageJpeg(String sourcePath) async {
    final sourceBytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException(
        'De gekozen afbeelding kon niet worden gelezen.',
      );
    }

    final oriented = img.bakeOrientation(decoded);
    final cleanBytes = Uint8List.fromList(img.encodeJpg(oriented, quality: 92));
    final paths = await storagePaths();
    final directory = Directory(paths.staging);
    await directory.create(recursive: true);
    final name = await _uniqueName(directory);
    final temporary = File(path.join(directory.path, '$name.part'));
    final destination = File(path.join(directory.path, name));
    try {
      await temporary.writeAsBytes(cleanBytes, flush: true);
      await temporary.rename(destination.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      if (await destination.exists()) await destination.delete();
      rethrow;
    }

    return StagedImage(
      path: destination.path,
      sha256: sha256.convert(cleanBytes).toString(),
      width: oriented.width,
      height: oriented.height,
      sizeBytes: cleanBytes.length,
    );
  }

  /// Atomically moves a verified staged image into permanent private storage.
  Future<StoredImage> finalizeStagedImage(StagedImage staged) async {
    final paths = await storagePaths();
    if (!paths.isStaged(staged.path)) {
      throw ArgumentError.value(
        staged.path,
        'staged.path',
        'The image does not belong to this staging directory.',
      );
    }
    final source = File(staged.path);
    if (!await source.exists()) {
      throw StateError('Het tijdelijke fotobestand bestaat niet meer.');
    }
    final stat = await source.stat();
    final digest = await sha256.bind(source.openRead()).first;
    if (stat.size != staged.sizeBytes || digest.toString() != staged.sha256) {
      throw StateError(
        'Het tijdelijke fotobestand is gewijzigd of beschadigd.',
      );
    }

    final originals = Directory(paths.originals);
    await originals.create(recursive: true);
    final destination = File(
      path.join(originals.path, await _uniqueName(originals)),
    );
    await source.rename(destination.path);
    return StoredImage(
      path: destination.path,
      sha256: staged.sha256,
      width: staged.width,
      height: staged.height,
      sizeBytes: staged.sizeBytes,
    );
  }

  /// Idempotently removes a single staged image after cancel or failure.
  Future<void> discardStagedImage(StagedImage staged) async {
    final paths = await storagePaths();
    if (!paths.isStaged(staged.path)) {
      throw ArgumentError.value(
        staged.path,
        'staged.path',
        'Refusing to remove a file outside the staging directory.',
      );
    }
    final file = File(staged.path);
    if (await file.exists()) await file.delete();
  }

  /// Removes abandoned complete and partial staging files older than [olderThan].
  Future<int> cleanupStaging({
    Duration olderThan = const Duration(hours: 24),
  }) async {
    if (olderThan.isNegative) {
      throw ArgumentError.value(
        olderThan,
        'olderThan',
        'Must not be negative.',
      );
    }
    final paths = await storagePaths();
    final directory = Directory(paths.staging);
    if (!await directory.exists()) return 0;

    final cutoff = _now().toUtc().subtract(olderThan);
    var removed = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !paths.isStaged(entity.path)) continue;
      final stat = await entity.stat();
      if (!stat.modified.toUtc().isAfter(cutoff)) {
        await entity.delete();
        removed++;
      }
    }
    return removed;
  }

  /// Idempotently deletes an owned permanent photo.
  ///
  /// Legacy v1 images directly below `target_images` are accepted as owned so
  /// migration and session deletion remain safe. No external path is accepted.
  Future<void> deleteStoredImage(String imagePath) async {
    final paths = await storagePaths();
    if (!paths.owns(imagePath) || paths.isStaged(imagePath)) {
      throw ArgumentError.value(
        imagePath,
        'imagePath',
        'Refusing to remove a file outside permanent photo storage.',
      );
    }
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }

  Future<ImageStoragePaths> storagePaths() async {
    final root = await _applicationDocumentsDirectory();
    return ImageStoragePaths(root.path);
  }

  Future<String> _uniqueName(Directory directory) async {
    final timestamp = _now().toUtc().microsecondsSinceEpoch;
    final safeToken = _tokenFactory().replaceAll(RegExp('[^a-zA-Z0-9_-]'), '');
    final stem = 'target-$timestamp-${safeToken.isEmpty ? 'image' : safeToken}';
    var suffix = 0;
    while (true) {
      final name = suffix == 0 ? '$stem.jpg' : '$stem-$suffix.jpg';
      if (!await File(path.join(directory.path, name)).exists() &&
          !await File(path.join(directory.path, '$name.part')).exists()) {
        return name;
      }
      suffix++;
    }
  }

  static String _randomToken() {
    final random = Random.secure();
    return List.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
