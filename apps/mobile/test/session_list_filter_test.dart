import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
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

  test('session list filters status and start date inside SQLite', () async {
    final completed = await repository.startQuickSession();
    await repository.saveSeriesDraft(
      seriesId: completed.draftSeriesId,
      target: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
      projectileDiameterMm: 5.6,
      impacts: const [ShotImpact(id: 'old-shot', xMm: 0, yMm: 0)],
    );
    await repository.confirmSeries(completed.draftSeriesId);
    final oldDate = DateTime.utc(2025, 1, 1);
    await repository.updateSessionDetails(
      sessionId: completed.sessionId,
      startedAtUtc: oldDate,
      localUtcOffsetMinutes: 60,
      rangeId: null,
      trainingGoal: 'Oud',
      conditions: null,
      notes: null,
    );
    await repository.completeSession(completed.sessionId);

    final active = await repository.startQuickSession();
    final activeOnly = await repository
        .watchSessionListItems(
          const SessionListFilters(status: SessionListStatusFilter.active),
        )
        .first;
    final completedOnly = await repository
        .watchSessionListItems(
          const SessionListFilters(status: SessionListStatusFilter.completed),
        )
        .first;
    final recentOnly = await repository
        .watchSessionListItems(
          SessionListFilters(
            startedAtOrAfterUtc: DateTime.now().toUtc().subtract(
              const Duration(days: 30),
            ),
          ),
        )
        .first;

    expect(activeOnly.map((item) => item.session.id), [active.sessionId]);
    expect(completedOnly.map((item) => item.session.id), [completed.sessionId]);
    expect(recentOnly.map((item) => item.session.id), [active.sessionId]);
  });

  test('filter value equality is stable for Riverpod family caching', () {
    final cutoff = DateTime.utc(2026, 7, 1);
    expect(
      SessionListFilters(
        status: SessionListStatusFilter.completed,
        startedAtOrAfterUtc: cutoff,
      ),
      SessionListFilters(
        status: SessionListStatusFilter.completed,
        startedAtOrAfterUtc: cutoff,
      ),
    );
  });
}
