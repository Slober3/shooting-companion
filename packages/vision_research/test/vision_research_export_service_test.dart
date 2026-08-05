import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart'
    as geometry;
import 'package:shooting_companion_vision_research/vision_research.dart';
import 'package:test/test.dart';

void main() {
  const password = 'research-password-123';
  final fixedNow = DateTime.utc(2026, 8, 4, 12, 30);

  VisionResearchExportService service({VisionResearchLimits? limits}) =>
      VisionResearchExportService(
        limits: limits ?? const VisionResearchLimits(),
        now: () => fixedNow,
        randomBytes: (length) => Uint8List.fromList(
          List<int>.generate(length, (index) => (index * 17 + 3) & 0xff),
        ),
      );

  test('roundtrip contains only the privacy-safe research payload', () async {
    final source = _jpegWithExifDescription('PRIVATE PERSON AND GPS');
    final encrypted = await service().createEncryptedExport(
      _request(cropBytes: source, cropMediaType: VisionCropMediaType.jpeg),
      password,
    );

    expect(encrypted.sublist(0, 4), [0x53, 0x43, 0x56, 0x31]);
    final inspection = await service().inspectEncryptedBytes(
      encrypted,
      password,
    );
    final decoded = await service().readEncryptedBytes(encrypted, password);

    expect(inspection.createdAtUtc, fixedNow);
    expect(inspection.profileVersionedId, 'test-target@1');
    expect(inspection.projectileDiameterMm, 5.6);
    expect(inspection.impactCount, 2);
    expect(inspection.imageWidth, 64);
    expect(inspection.imageHeight, 48);
    expect(inspection.cropSha256, hasLength(64));
    expect(inspection.manifestSha256, hasLength(64));
    expect(decoded.impacts, hasLength(2));
    expect(decoded.impacts.first.ordinal, 1);
    expect(decoded.impacts.first.xMm, 4.5);
    expect(decoded.targetProfileSnapshot.versionedId, 'test-target@1');
    expect(
      decoded.alignment.algorithmVersion,
      geometry.manualHomographyAlgorithmVersion,
    );

    final sanitizedText = latin1.decode(
      decoded.croppedTargetBytes,
      allowInvalid: true,
    );
    expect(sanitizedText, isNot(contains('PRIVATE PERSON')));
    expect(sanitizedText, isNot(contains('Exif')));
    final records = jsonEncode(decoded.toPrivacySafeRecordsJson());
    expect(records, isNot(contains('sourceImageId')));
    expect(records, isNot(contains('private-source-id')));
    expect(records, isNot(contains('private-image-id')));
    expect(records, isNot(contains('locationDescription')));
    expect(records, isNot(contains('sessionId')));
    expect(records, isNot(contains('sessionNote')));
    expect(records, isNot(contains('displayName')));
    expect(records, isNot(contains('Synthetic target')));
    expect(records, isNot(contains('Test fixture')));
    expect(decoded.consent.explicitConsent, isTrue);
  });

  test('PNG text metadata is stripped before it is encrypted', () async {
    final canvas = _canvas();
    canvas.textData = {'Comment': 'PRIVATE RANGE LOCATION'};
    final source = image.encodePng(canvas);
    expect(
      latin1.decode(source, allowInvalid: true),
      contains('PRIVATE RANGE'),
    );

    final encrypted = await service().createEncryptedExport(
      _request(cropBytes: source, cropMediaType: VisionCropMediaType.png),
      password,
    );
    final decoded = await service().readEncryptedBytes(encrypted, password);
    final sanitized = latin1.decode(
      decoded.croppedTargetBytes,
      allowInvalid: true,
    );
    expect(sanitized, isNot(contains('PRIVATE RANGE')));
    expect(sanitized, isNot(contains('tEXt')));
  });

  test('wrong password and a modified container are rejected', () async {
    final encrypted = await service().createEncryptedExport(
      _request(),
      password,
    );
    await expectLater(
      service().inspectEncryptedBytes(encrypted, 'wrong-password-123'),
      throwsA(isA<FormatException>()),
    );

    final modified = Uint8List.fromList(encrypted);
    modified[modified.length - 1] ^= 0x01;
    await expectLater(
      service().inspectEncryptedBytes(modified, password),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'manifest serialization is deterministic despite encrypted nonces',
    () async {
      var seed = 0;
      final randomized = VisionResearchExportService(
        now: () => fixedNow,
        randomBytes: (length) => Uint8List.fromList(
          List<int>.generate(length, (_) => (seed++ * 31 + 7) & 0xff),
        ),
      );
      final first = await randomized.createEncryptedExport(
        _request(),
        password,
      );
      final second = await randomized.createEncryptedExport(
        _request(),
        password,
      );
      expect(first, isNot(equals(second)));

      final firstInspection = await randomized.inspectEncryptedBytes(
        first,
        password,
      );
      final secondInspection = await randomized.inspectEncryptedBytes(
        second,
        password,
      );
      expect(firstInspection.manifestSha256, secondInspection.manifestSha256);
      expect(firstInspection.cropSha256, secondInspection.cropSha256);
    },
  );

  test('explicit scoped consent is mandatory', () async {
    final invalid = _request(
      consent: VisionResearchConsent(
        explicitConsent: false,
        consentTextVersion: 'vision-consent-v1',
        acceptedAtUtc: fixedNow,
        allowsAlgorithmValidation: true,
        allowsModelTraining: false,
        allowsPublicResearchRelease: false,
      ),
    );
    await expectLater(
      service().createEncryptedExport(invalid, password),
      throwsA(isA<FormatException>()),
    );
  });

  test('unreviewed quality cannot be combined with assessed labels', () async {
    final invalid = _request(
      qualityLabels: {
        VisionQualityLabel.unreviewed,
        VisionQualityLabel.adequateSharpness,
      },
    );
    await expectLater(
      service().createEncryptedExport(invalid, password),
      throwsA(isA<FormatException>()),
    );
  });

  test('unknown target bull references are rejected', () async {
    final invalid = _request(
      impacts: const [
        ShotImpact(
          id: 'private-database-id',
          xMm: 0,
          yMm: 0,
          targetBullId: 'unknown-bull',
        ),
      ],
    );
    await expectLater(
      service().createEncryptedExport(invalid, password),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'input and container limits are checked before expensive work',
    () async {
      final constrained = service(
        limits: const VisionResearchLimits(
          maximumInputCropBytes: 100,
          maximumSanitizedCropBytes: 1024,
          maximumContainerBytes: 2048,
          maximumMetadataBytes: 1024,
          maximumImagePixels: 10000,
        ),
      );
      await expectLater(
        constrained.createEncryptedExport(_request(), password),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        constrained.inspectEncryptedBytes(Uint8List(2049), password),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('file writer streams to .scvision and never overwrites', () async {
    final directory = await Directory.systemTemp.createTemp('scvision-test-');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final destination = File('${directory.path}/fixture.scvision');
    final written = await service().writeEncryptedExport(
      destination: destination,
      request: _request(),
      password: password,
    );
    expect(await written.exists(), isTrue);
    final before = await written.readAsBytes();
    final inspection = await service().inspectEncryptedFile(written, password);
    expect(inspection.impactCount, 2);

    await expectLater(
      service().writeEncryptedExport(
        destination: destination,
        request: _request(),
        password: password,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await written.readAsBytes(), before);
  });

  test('alignment dimensions must match the target snapshot', () async {
    final wrongAlignment = _alignment(width: 500, height: 500);
    final invalid = _request(alignment: wrongAlignment);
    await expectLater(
      service().createEncryptedExport(invalid, password),
      throwsA(isA<FormatException>()),
    );
  });
}

VisionResearchExportRequest _request({
  Uint8List? cropBytes,
  VisionCropMediaType cropMediaType = VisionCropMediaType.jpeg,
  List<ShotImpact>? impacts,
  geometry.ManualPhotoAlignment? alignment,
  Set<VisionQualityLabel>? qualityLabels,
  VisionResearchConsent? consent,
}) => VisionResearchExportRequest(
  croppedTargetBytes: cropBytes ?? image.encodeJpg(_canvas(), quality: 90),
  cropMediaType: cropMediaType,
  targetProfileSnapshot: _target(),
  projectileDiameterMm: 5.6,
  confirmedManualImpacts:
      impacts ??
      const [
        ShotImpact(
          id: 'private-source-id-1',
          xMm: 4.5,
          yMm: -3.2,
          sourceImageId: 'private-image-id',
          imageXNormalized: 0.51,
          imageYNormalized: 0.49,
          rawScoreValue: 10,
        ),
        ShotImpact(
          id: 'private-source-id-2',
          xMm: 10,
          yMm: 8,
          multiplicity: 2,
          isPositionUncertain: true,
          rawScoreValue: 9,
        ),
      ],
  alignment: alignment ?? _alignment(),
  qualityLabels:
      qualityLabels ??
      {
        VisionQualityLabel.ringsFullyVisible,
        VisionQualityLabel.adequateSharpness,
      },
  consent:
      consent ??
      VisionResearchConsent(
        explicitConsent: true,
        consentTextVersion: 'vision-consent-v1',
        acceptedAtUtc: DateTime.utc(2026, 8, 4, 12),
        allowsAlgorithmValidation: true,
        allowsModelTraining: false,
        allowsPublicResearchRelease: false,
      ),
);

TargetProfile _target() => TargetProfile(
  schemaVersion: 1,
  profileId: 'test-target',
  profileVersion: 1,
  displayName: 'Synthetic target',
  authority: 'Test fixture',
  rulesEdition: '1',
  physicalCardWidthMm: 550,
  physicalCardHeightMm: 550,
  rings: const [
    RingZone(value: 10, outerDiameterMm: 50),
    RingZone(value: 9, outerDiameterMm: 100),
  ],
  lineThicknessMm: 0.2,
  lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
  validationStatus: ValidationStatus.experimental,
);

geometry.ManualPhotoAlignment _alignment({
  double width = 550,
  double height = 550,
}) {
  final result = geometry.ManualPhotoAlignment.build(
    corners: const geometry.NormalizedQuad(
      topLeft: geometry.NormalizedPoint(0, 0),
      topRight: geometry.NormalizedPoint(1, 0),
      bottomRight: geometry.NormalizedPoint(1, 1),
      bottomLeft: geometry.NormalizedPoint(0, 1),
    ),
    cardWidthMm: width,
    cardHeightMm: height,
  );
  return result.alignment!;
}

image.Image _canvas() {
  final canvas = image.Image(width: 64, height: 48);
  image.fill(canvas, color: image.ColorRgb8(235, 230, 210));
  image.fillCircle(
    canvas,
    x: 32,
    y: 24,
    radius: 12,
    color: image.ColorRgb8(30, 30, 30),
  );
  return canvas;
}

Uint8List _jpegWithExifDescription(String description) {
  final canvas = _canvas();
  canvas.exif.imageIfd[0x010e] = image.IfdValueAscii(description);
  final encoded = image.encodeJpg(canvas, quality: 90);
  expect(latin1.decode(encoded, allowInvalid: true), contains('Exif'));
  expect(latin1.decode(encoded, allowInvalid: true), contains(description));
  return encoded;
}
