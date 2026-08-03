import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:shooting_companion/services/image_storage_service.dart';

void main() {
  late Directory temporaryDirectory;
  late ImageStorageService service;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'shooting-photo-store-',
    );
    service = ImageStorageService(
      applicationDocumentsDirectory: () async => temporaryDirectory,
      now: () => DateTime.utc(2026, 8, 3, 12),
      tokenFactory: () => 'fixed-token',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'stage and finalize produce a verified EXIF-free private JPEG',
    () async {
      final source = File(path.join(temporaryDirectory.path, 'source.png'));
      final sourceImage = img.Image(width: 32, height: 24)
        ..setPixelRgb(2, 3, 220, 30, 10);
      await source.writeAsBytes(img.encodePng(sourceImage));

      final staged = await service.stageJpeg(source.path);
      expect(staged.path, contains(path.join('target_images', 'staging')));
      expect(await File(staged.path).exists(), isTrue);
      expect(staged.width, 32);
      expect(staged.height, 24);

      final stored = await service.finalizeStagedImage(staged);
      expect(stored.path, contains(path.join('target_images', 'originals')));
      expect(await File(staged.path).exists(), isFalse);
      expect(await File(stored.path).exists(), isTrue);
      expect(stored.sha256, staged.sha256);

      final decoded = img.decodeJpg(await File(stored.path).readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, 32);
      expect(decoded.height, 24);
      expect(decoded.exif.isEmpty, isTrue);
    },
  );

  test(
    'tampered staging file is refused and remains available for cleanup',
    () async {
      final source = await _writeSource(temporaryDirectory);
      final staged = await service.stageJpeg(source.path);
      await File(staged.path).writeAsString('tampered');

      await expectLater(
        service.finalizeStagedImage(staged),
        throwsA(isA<StateError>()),
      );
      expect(await File(staged.path).exists(), isTrue);
      await service.discardStagedImage(staged);
      expect(await File(staged.path).exists(), isFalse);
    },
  );

  test(
    'delete is idempotent but refuses paths outside owned storage',
    () async {
      final source = await _writeSource(temporaryDirectory);
      final stored = await service.importJpeg(source.path);

      await service.deleteStoredImage(stored.path);
      await service.deleteStoredImage(stored.path);
      expect(await File(stored.path).exists(), isFalse);

      await expectLater(
        service.deleteStoredImage(source.path),
        throwsA(isA<ArgumentError>()),
      );
      expect(await source.exists(), isTrue);
    },
  );

  test(
    'path policy accepts legacy originals but never staging as permanent',
    () {
      final paths = ImageStoragePaths(temporaryDirectory.path);
      final legacy = path.join(paths.root, 'legacy-v1.jpg');
      final staged = path.join(paths.staging, 'pending.jpg');

      expect(paths.owns(legacy), isTrue);
      expect(paths.isOriginal(legacy), isFalse);
      expect(paths.isStaged(staged), isTrue);
      expect(
        paths.owns(path.join(temporaryDirectory.parent.path, 'other.jpg')),
        isFalse,
      );
    },
  );
}

Future<File> _writeSource(Directory directory) async {
  final source = File(path.join(directory.path, 'source.png'));
  final sourceImage = img.Image(width: 16, height: 12)
    ..setPixelRgb(1, 1, 10, 20, 30);
  await source.writeAsBytes(img.encodePng(sourceImage));
  return source;
}
