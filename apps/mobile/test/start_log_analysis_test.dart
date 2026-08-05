import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/history/history_screen.dart';
import 'package:shooting_companion/features/progress/progress_screen.dart';
import 'package:shooting_companion/features/today/today_screen.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;

  setUpAll(() => initializeDateFormatting('nl_BE'));

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
    await repository.seedDefaults();
  });

  tearDown(() => database.close());

  testWidgets('Start blijft rustig op 320 dp met 200 procent tekst', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(320, 640));
    await tester.pumpWidget(
      _testApp(database: database, child: const TodayScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Nieuwe sessie'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Volledig lokaal'), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeTestTree(tester);
  });

  testWidgets('Logboek toont alle zichtbare sessieacties zonder long press', (
    tester,
  ) async {
    final quick = await _createConfirmedSession(repository);
    await repository.completeSession(quick.sessionId);

    _setSurfaceSize(tester, const Size(320, 640));
    await tester.pumpWidget(
      _testApp(database: database, child: const HistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Logboek'), findsOneWidget);
    expect(find.byTooltip('Sessieacties'), findsOneWidget);
    await tester.tap(find.byTooltip('Sessieacties'));
    await tester.pumpAndSettle();

    expect(find.text('Bekijken'), findsOneWidget);
    expect(find.text('Bewerken'), findsOneWidget);
    expect(find.text('Verdergaan'), findsOneWidget);
    expect(find.text('Verwijderen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTestTree(tester);
  });

  testWidgets('Analyse gebruikt werkelijke schoten en leesbare kaartnaam', (
    tester,
  ) async {
    await _createConfirmedSession(repository);

    _setSurfaceSize(tester, const Size(320, 900));
    await tester.pumpWidget(
      _testApp(database: database, child: const ProgressScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analyse'), findsOneWidget);
    expect(find.text('Schoten'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Gemiddelde score'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('ISSF 25 m Precision / 50 m Pistol'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTestTree(tester);
  });

  testWidgets('Analyse laat een oudere reeks expliciet kiezen', (tester) async {
    final older = await _createConfirmedSession(repository);
    await repository.completeSession(older.sessionId);
    await _setSessionDate(database, older.sessionId, DateTime(2026, 8, 1, 9));
    final newer = await _createConfirmedSession(repository);
    await repository.completeSession(newer.sessionId);
    await _setSessionDate(database, newer.sessionId, DateTime(2026, 8, 4, 9));
    for (var day = 5; day <= 8; day++) {
      final additional = await _createConfirmedSession(repository);
      await repository.completeSession(additional.sessionId);
      await _setSessionDate(
        database,
        additional.sessionId,
        DateTime(2026, 8, day, 9),
      );
    }

    _setSurfaceSize(tester, const Size(412, 915));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(412, 915)),
            child: const ProgressScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Vergelijken'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Kies reeks'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Kies reeks'));
    await tester.pumpAndSettle();

    expect(find.text('Kies een reeks'), findsOneWidget);
    expect(find.textContaining('4 aug 2026'), findsOneWidget);
    await tester.dragUntilVisible(
      find.textContaining('1 aug 2026'),
      find.byType(Scrollable).last,
      const Offset(0, -300),
    );
    expect(find.textContaining('1 aug 2026'), findsOneWidget);
    await tester.tap(find.textContaining('1 aug 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Geselecteerde reeks'), findsOneWidget);
    expect(find.textContaining('1 augustus 2026'), findsOneWidget);
    expect(find.text('Volledige analyse'), findsOneWidget);

    await tester.ensureVisible(find.text('Samenstelling wijzigen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Samenstelling wijzigen'));
    await tester.pumpAndSettle();

    expect(
      find.text('5/5 geselecteerd. De bronreeks blijft altijd geselecteerd.'),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.textContaining('Bronreeks'),
      find.byType(Scrollable).last,
      const Offset(0, -300),
    );
    final sourceTile = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.textContaining('Bronreeks'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(sourceTile.value, isTrue);
    expect(sourceTile.onChanged, isNull);
    expect(tester.takeException(), isNull);
    await _disposeTestTree(tester);
  });

  testWidgets('potential score works from the Analyse tab', (tester) async {
    await _createConfirmedSession(repository);

    _setSurfaceSize(tester, const Size(412, 915));
    await tester.pumpWidget(
      _testApp(database: database, child: const ProgressScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vergelijken'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Potential score berekenen'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Potential score berekenen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potential score berekenen'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Potential score'), findsOneWidget);
    expect(
      find.textContaining('Beste score met hetzelfde trefbeeld'),
      findsOneWidget,
    );
    expect(find.textContaining('object is unsendable'), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeTestTree(tester);
  });
}

Future<void> _setSessionDate(
  AppDatabase database,
  String sessionId,
  DateTime value,
) =>
    (database.update(database.trainingSessions)
          ..where((row) => row.id.equals(sessionId)))
        .write(TrainingSessionsCompanion(startedAtUtc: drift.Value(value)));

Future<QuickSessionResult> _createConfirmedSession(
  ShootingRepository repository,
) async {
  final quick = await repository.startQuickSession();
  await repository.saveSeriesDraft(
    seriesId: quick.draftSeriesId,
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: 5.6,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
    impacts: [
      ShotImpact(id: '${quick.draftSeriesId}-center', xMm: 0, yMm: 0),
      ShotImpact(id: '${quick.draftSeriesId}-nine', xMm: 30, yMm: 0),
    ],
  );
  await repository.confirmSeries(quick.draftSeriesId);
  return quick;
}

Widget _testApp({required AppDatabase database, required Widget child}) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: child,
      ),
    ),
  );
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _disposeTestTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}
