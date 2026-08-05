import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/services/export_service.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('nl_BE'));

  test('CSV exports actual shots, stored maximum, notes and photo count', () {
    final csv = ExportFormatter.buildCsv([
      ExportSeriesRow(
        sessionId: 'session-1',
        sessionStartedAtUtc: DateTime.utc(2026, 1, 2, 10),
        sessionStatus: 'completed',
        sequenceNumber: 3,
        targetName: 'Custom zevenring',
        distanceMeters: 25,
        shotCount: 3,
        totalScore: 14,
        maximumPossibleScore: 21,
        innerTenCount: 0,
        missCount: 1,
        projectileDiameterMm: 5.6,
        photoCount: 2,
        firearmName: 'Walther GSP',
        ammoLotName: 'Eley Club',
        notes: 'Rustig, "vaste" houding',
      ),
    ]);

    expect(csv, contains('geregistreerde_schoten'));
    expect(csv, contains('timer_run_count'));
    expect(csv, isNot(contains('verwachte_schoten')));
    expect(
      csv,
      contains(
        '"3","14","21","66.67","0","1","5.6",'
        '"Walther GSP","Eley Club","Rustig, ""vaste"" houding","2"',
      ),
    );
  });

  test('target snapshot yields readable name with safe fallback', () {
    expect(
      ExportFormatter.targetDisplayName(
        '{"displayName":"ISSF 25 m Precision"}',
        'internal@1',
      ),
      'ISSF 25 m Precision',
    );
    expect(
      ExportFormatter.targetDisplayName('{not json', 'internal@1'),
      'internal@1',
    );
    expect(
      ExportFormatter.targetDisplayName('{"displayName":"  "}', 'custom@2'),
      'custom@2',
    );
  });

  test('zero maximum produces a finite zero percentage', () {
    final row = ExportSeriesRow(
      sessionId: 'draft',
      sessionStartedAtUtc: DateTime.utc(2026),
      sessionStatus: 'active',
      sequenceNumber: 1,
      targetName: 'Doel',
      distanceMeters: 25,
      shotCount: 0,
      totalScore: 0,
      maximumPossibleScore: 0,
      innerTenCount: 0,
      missCount: 0,
      projectileDiameterMm: 5.6,
      photoCount: 0,
    );

    expect(row.percentage, 0);
    expect(ExportFormatter.buildCsv([row]), contains('"0.00"'));
  });

  test('database-backed export joins only confirmed report rows', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final quick = await repository.startQuickSession();
    await repository.saveSeriesDraft(
      seriesId: quick.draftSeriesId,
      target: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
      projectileDiameterMm: 5.6,
      impacts: const [ShotImpact(id: 'center', xMm: 0, yMm: 0)],
      notes: 'Unicode é – klaar',
    );
    await repository.confirmSeries(quick.draftSeriesId);
    final output = Directory('build/test-output')..createSync(recursive: true);
    final photoFile = File('${output.path}/export-photo.jpg');
    final photoBytes = _syntheticPhotoBytes();
    await photoFile.writeAsBytes(photoBytes, flush: true);
    await repository.attachImage(
      NewImageAsset(
        id: 'export-photo',
        sessionId: quick.sessionId,
        seriesId: quick.draftSeriesId,
        role: ImageRole.attachment,
        path: photoFile.path,
        sha256: 'export-photo-hash',
        width: 64,
        height: 48,
        sizeBytes: photoBytes.length,
        caption: 'Opstelling é – stabiele steun',
      ),
    );
    await repository.saveCompletedTimerActivity(
      id: 'export-timer',
      kind: StoredTrainingActivityKind.acousticLiveFire,
      seriesId: quick.draftSeriesId,
      configuration: const {'mode': 'acousticLiveFire'},
      summary: const {
        'countedShotCount': 1,
        'firstShotTimeMicros': 1100000,
        'totalTimeMicros': 1100000,
      },
      events: const [
        NewShotTimerEvent(
          id: 'export-timer-event',
          elapsedMicroseconds: 1100000,
          splitMicroseconds: 1100000,
          source: StoredTimerEventSource.acoustic,
        ),
      ],
      startedAtUtc: DateTime.utc(2026, 8, 3, 23),
      localUtcOffsetMinutes: 120,
      completedAtUtc: DateTime.utc(2026, 8, 3, 23, 0, 2),
    );
    await repository.saveCompletedTimerActivity(
      id: 'export-external-summary',
      kind: StoredTrainingActivityKind.externalManual,
      seriesId: quick.draftSeriesId,
      configuration: const {'mode': 'externalManual'},
      summary: const {
        'countedShotCount': null,
        'firstShotTimeMicros': 1140000,
        'lastShotTimeMicros': 4720000,
        'totalTimeMicros': 4720000,
        'externalTimingCompleteness': 'summaryOnly',
        'shotCountKnown': false,
        'userEdited': true,
      },
      events: const [],
      startedAtUtc: DateTime.utc(2026, 8, 3, 23, 1),
      localUtcOffsetMinutes: 120,
      completedAtUtc: DateTime.utc(2026, 8, 3, 23, 1, 5),
    );
    final completedDrillId = await repository.createTrainingActivity(
      id: 'completed-drill',
      kind: StoredTrainingActivityKind.drill,
      status: StoredTrainingActivityStatus.completed,
      sessionId: quick.sessionId,
      summary: const {'countedShotCount': 99, 'totalTimeMicros': 99000000},
      startedAtUtc: DateTime.utc(2026, 8, 3, 22),
      localUtcOffsetMinutes: 120,
      completedAtUtc: DateTime.utc(2026, 8, 3, 22, 10),
    );
    await repository.linkTrainingActivityToSeries(
      completedDrillId,
      quick.draftSeriesId,
    );
    final draftTimerId = await repository.createTrainingActivity(
      id: 'draft-timer',
      kind: StoredTrainingActivityKind.par,
      status: StoredTrainingActivityStatus.draft,
      sessionId: quick.sessionId,
      summary: const {'countedShotCount': 0, 'totalTimeMicros': 5000000},
      startedAtUtc: DateTime.utc(2026, 8, 3, 22, 30),
      localUtcOffsetMinutes: 120,
    );
    await repository.linkTrainingActivityToSeries(
      draftTimerId,
      quick.draftSeriesId,
    );
    final service = ExportService(
      database,
      temporaryDirectory: () async => output,
      now: () => DateTime(2026, 8, 3, 23, 27),
    );

    final csv = await (await service.createCsv()).readAsString();
    final timerRuns = await (await service.createTimerRunsCsv()).readAsString();
    final timerEvents = await (await service.createTimerEventsCsv())
        .readAsString();
    final pdf = await service.createPdfReport();

    expect(csv, contains('ISSF 25 m Precision / 50 m Pistol'));
    expect(csv, contains('Unicode é – klaar'));
    expect(csv, contains('"1"'));
    expect(csv, contains('timer_run_count'));
    expect(csv.trim().split('\r\n').last, endsWith(',"2"'));
    expect(timerRuns, contains('"export-timer"'));
    expect(timerRuns, contains('"1.100"'));
    final summaryOnlyRun = timerRuns
        .split('\r\n')
        .singleWhere((line) => line.contains('"export-external-summary"'));
    final summaryOnlyCells = summaryOnlyRun.split(',');
    expect(summaryOnlyCells[7], '""');
    expect(summaryOnlyCells[8], '"0"');
    expect(summaryOnlyCells[9], '"1.140"');
    expect(summaryOnlyCells[10], '"4.720"');
    expect(timerEvents, contains('"export-timer-event"'));
    expect(timerEvents, isNot(contains('"export-external-summary"')));
    expect(timerEvents, contains('"1.100"'));
    expect(await pdf.length(), greaterThan(photoBytes.length));
    expect(await photoFile.readAsBytes(), photoBytes);
  });

  test(
    'PDF embeds Unicode fonts and produces a multipage QA fixture',
    () async {
      final rows = [
        for (var index = 0; index < 55; index++)
          ExportSeriesRow(
            sessionId: 'session-${index ~/ 5}',
            sessionStartedAtUtc: DateTime.utc(2026, 8, 3, 20, index % 60),
            sessionStatus: 'completed',
            sequenceNumber: index % 5 + 1,
            targetName:
                'Doelkaart é ë ï ’ – — met een bewust lange beschrijvende naam',
            distanceMeters: 25,
            shotCount: 10,
            totalScore: 84,
            maximumPossibleScore: 100,
            innerTenCount: 2,
            missCount: 0,
            projectileDiameterMm: 5.6,
            photoCount: 1,
            photos: index == 0
                ? [
                    PdfReportPhoto(
                      id: 'photo-with-caption',
                      bytes: _syntheticPhotoBytes(),
                      roleLabel: 'Scorefoto',
                      caption: 'Opstelling é – onderschrift bij de foto',
                    ),
                  ]
                : const [],
          ),
      ];
      final data = PdfReportData(
        seriesRows: rows,
        generatedAt: DateTime(2026, 8, 3, 23, 27),
      );
      final bytes = await PdfReportBuilder.build(
        data,
        await PdfFontBundle.loadFromAssets(),
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(10000));
      expect(data.sessionCount, 11);
      expect(data.seriesCount, 55);
      expect(data.includedPhotoCount, 1);

      final output = Directory('build/test-output')
        ..createSync(recursive: true);
      await File(
        '${output.path}/unicode-report.pdf',
      ).writeAsBytes(bytes, flush: true);
    },
  );
}

Uint8List _syntheticPhotoBytes() {
  final image = image_lib.Image(width: 64, height: 48);
  image_lib.fill(image, color: image_lib.ColorRgb8(235, 230, 210));
  image_lib.fillCircle(
    image,
    x: 32,
    y: 24,
    radius: 12,
    color: image_lib.ColorRgb8(30, 30, 30),
  );
  return image_lib.encodeJpg(image, quality: 90);
}
