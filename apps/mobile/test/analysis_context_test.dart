import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/progress/analysis_context.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
    await repository.seedDefaults();
  });

  tearDown(() => database.close());

  test(
    'analysis dataset keeps parent session and archived material names',
    () async {
      final fixture = await _createFixture(database, repository);

      expect(
        await repository.removeFirearm(fixture.firearmId),
        LibraryRemovalResult.archived,
      );
      expect(
        await repository.removeAmmoLot(fixture.ammoAId),
        LibraryRemovalResult.archived,
      );

      final dataset = await repository.watchAnalysisDataset().first;
      final selected = dataset.singleWhere(
        (item) => item.series.id == fixture.sessionAFirstSeriesId,
      );
      expect(selected.session.id, fixture.sessionAId);
      expect(
        selected.session.startedAtUtc.toUtc(),
        fixture.sessionAStartedAtUtc,
      );
      expect(selected.firearm?.name, 'Historisch geweer');
      expect(selected.firearm?.archived, isTrue);
      expect(selected.ammoLot?.displayName, 'Historische partij A');
      expect(selected.ammoLot?.archived, isTrue);
    },
  );

  test(
    'context splits a session strictly and orders by session chronology',
    () async {
      final fixture = await _createFixture(database, repository);
      final dataset = await repository.watchAnalysisDataset().first;
      final catalog = AnalysisContextCatalog.fromDataset(dataset);

      final session = catalog.session(fixture.sessionAId)!;
      expect(session.series.map((item) => item.series.sequenceNumber), [1, 2]);
      expect(session.cohorts, hasLength(2));
      expect(session.cohorts.map((cohort) => cohort.key.ammoLotId).toSet(), {
        fixture.ammoAId,
        fixture.ammoBId,
      });

      final comparison = catalog.comparableForSeries(
        fixture.sessionAFirstSeriesId,
      )!;
      expect(comparison.selected.series.id, fixture.sessionAFirstSeriesId);
      expect(comparison.series.map((item) => item.series.id), [
        fixture.sessionBSeriesId,
        fixture.sessionAFirstSeriesId,
      ]);
      expect(comparison.analysis.seriesAnalyses.map((item) => item.seriesId), [
        fixture.sessionBSeriesId,
        fixture.sessionAFirstSeriesId,
      ]);
      expect(
        comparison.series.map((item) => item.series.id),
        isNot(contains(fixture.sessionASecondSeriesId)),
      );
    },
  );

  test(
    'family providers expose series, session and comparable contexts',
    () async {
      final fixture = await _createFixture(database, repository);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await container.read(analysisDatasetProvider.future);
      await Future<void>.delayed(Duration.zero);

      final series = container
          .read(seriesAnalysisContextProvider(fixture.sessionAFirstSeriesId))
          .requireValue;
      final session = container
          .read(sessionAnalysisContextProvider(fixture.sessionAId))
          .requireValue;
      final comparison = container
          .read(
            comparableSeriesAnalysisContextProvider(
              fixture.sessionAFirstSeriesId,
            ),
          )
          .requireValue;

      expect(series?.session.id, fixture.sessionAId);
      expect(session?.series, hasLength(2));
      expect(comparison?.series, hasLength(2));
    },
  );
}

Future<_Fixture> _createFixture(
  AppDatabase database,
  ShootingRepository repository,
) async {
  final firearmId = await repository.addFirearm(
    name: 'Historisch geweer',
    type: FirearmType.rifle,
    defaultCartridgeId: CartridgePresets.twentyTwoLr.id,
  );
  final ammoAId = await repository.addAmmoLot(
    cartridgeId: CartridgePresets.twentyTwoLr.id,
    displayName: 'Historische partij A',
  );
  final ammoBId = await repository.addAmmoLot(
    cartridgeId: CartridgePresets.twentyTwoLr.id,
    displayName: 'Partij B',
  );
  final defaults = SeriesDefaults(
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
    firearmId: firearmId,
    ammoLotId: ammoAId,
  );

  final sessionA = await repository.startQuickSession(defaults: defaults);
  final sessionAStartedAtUtc = DateTime.utc(2026, 8, 2, 9);
  await _setSessionStart(database, sessionA.sessionId, sessionAStartedAtUtc);
  await _saveAndConfirm(
    repository,
    seriesId: sessionA.draftSeriesId,
    firearmId: firearmId,
    ammoLotId: ammoAId,
    impacts: const [
      ShotImpact(id: 'a-center', xMm: 0, yMm: 0),
      ShotImpact(id: 'a-offset', xMm: 10, yMm: 0),
    ],
  );
  final sessionASecondSeriesId = await repository.createOrResumeDraftSeries(
    sessionA.sessionId,
  );
  await _saveAndConfirm(
    repository,
    seriesId: sessionASecondSeriesId,
    firearmId: firearmId,
    ammoLotId: ammoBId,
    impacts: const [
      ShotImpact(id: 'b-center', xMm: 0, yMm: 0),
      ShotImpact(id: 'b-offset', xMm: 20, yMm: 0),
    ],
  );
  await repository.completeSession(sessionA.sessionId);

  // Created later but deliberately backdated: analysis chronology must follow
  // the session visit, not the database insertion timestamp.
  final sessionB = await repository.startQuickSession(defaults: defaults);
  await _setSessionStart(
    database,
    sessionB.sessionId,
    DateTime.utc(2026, 8, 1, 9),
  );
  await _saveAndConfirm(
    repository,
    seriesId: sessionB.draftSeriesId,
    firearmId: firearmId,
    ammoLotId: ammoAId,
    impacts: const [
      ShotImpact(id: 'older-center', xMm: 0, yMm: 0),
      ShotImpact(id: 'older-offset', xMm: 30, yMm: 0),
    ],
  );
  await repository.completeSession(sessionB.sessionId);

  return _Fixture(
    firearmId: firearmId,
    ammoAId: ammoAId,
    ammoBId: ammoBId,
    sessionAId: sessionA.sessionId,
    sessionAStartedAtUtc: sessionAStartedAtUtc,
    sessionAFirstSeriesId: sessionA.draftSeriesId,
    sessionASecondSeriesId: sessionASecondSeriesId,
    sessionBSeriesId: sessionB.draftSeriesId,
  );
}

Future<void> _setSessionStart(
  AppDatabase database,
  String sessionId,
  DateTime startedAtUtc,
) =>
    (database.update(database.trainingSessions)
          ..where((row) => row.id.equals(sessionId)))
        .write(TrainingSessionsCompanion(startedAtUtc: Value(startedAtUtc)));

Future<void> _saveAndConfirm(
  ShootingRepository repository, {
  required String seriesId,
  required String firearmId,
  required String ammoLotId,
  required List<ShotImpact> impacts,
}) async {
  await repository.saveSeriesDraft(
    seriesId: seriesId,
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
    firearmId: firearmId,
    ammoLotId: ammoLotId,
    impacts: impacts,
  );
  await repository.confirmSeries(seriesId);
}

class _Fixture {
  const _Fixture({
    required this.firearmId,
    required this.ammoAId,
    required this.ammoBId,
    required this.sessionAId,
    required this.sessionAStartedAtUtc,
    required this.sessionAFirstSeriesId,
    required this.sessionASecondSeriesId,
    required this.sessionBSeriesId,
  });

  final String firearmId;
  final String ammoAId;
  final String ammoBId;
  final String sessionAId;
  final DateTime sessionAStartedAtUtc;
  final String sessionAFirstSeriesId;
  final String sessionASecondSeriesId;
  final String sessionBSeriesId;
}
