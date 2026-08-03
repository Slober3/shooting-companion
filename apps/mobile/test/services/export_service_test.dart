import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/services/export_service.dart';

void main() {
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
}
