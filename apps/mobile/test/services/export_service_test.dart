import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
        notes: 'Rustig, "vaste" houding',
      ),
    ]);

    expect(csv, contains('geregistreerde_schoten'));
    expect(csv, isNot(contains('verwachte_schoten')));
    expect(
      csv,
      contains(
        '"3","14","21","66.67","0","1","5.6",'
        '"Rustig, ""vaste"" houding","2"',
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
    await repository.attachImage(
      NewImageAsset(
        id: 'export-photo',
        sessionId: quick.sessionId,
        seriesId: quick.draftSeriesId,
        role: ImageRole.attachment,
        path: 'export-photo.jpg',
        sha256: 'export-photo-hash',
        width: 1200,
        height: 900,
        sizeBytes: 10,
      ),
    );
    final output = Directory('build/test-output')..createSync(recursive: true);
    final service = ExportService(
      database,
      temporaryDirectory: () async => output,
      now: () => DateTime(2026, 8, 3, 23, 27),
    );

    final csv = await (await service.createCsv()).readAsString();

    expect(csv, contains('ISSF 25 m Precision / 50 m Pistol'));
    expect(csv, contains('Unicode é – klaar'));
    expect(csv, contains('"1"'));
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

      final output = Directory('build/test-output')
        ..createSync(recursive: true);
      await File(
        '${output.path}/unicode-report.pdf',
      ).writeAsBytes(bytes, flush: true);
    },
  );
}
