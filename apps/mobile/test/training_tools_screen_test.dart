import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/training_tools/drill_plan_screen.dart';
import 'package:shooting_companion/features/training_tools/training_tools.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
  });

  tearDown(() => database.close());

  testWidgets('hub exposes five destinations, planner and existing tools', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const TrainingToolsScreen(), database, repository),
    );
    await _pumpUi(tester);

    expect(find.text('Leren & oefenen'), findsOneWidget);
    _expectFiveAdaptiveDestinations(tester);

    await _scrollStartTo(tester, 'training-tool-planner');
    await tester.tap(find.byKey(const ValueKey('training-tool-planner')));
    await _pumpUi(tester);
    expect(find.text('Training plannen'), findsWidgets);
    expect(find.byKey(const ValueKey('drill-plan-duration')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      _app(const TrainingToolsScreen(), database, repository),
    );
    await _pumpUi(tester);

    for (final key in const [
      'training-tool-planner',
      'training-tool-learning-paths',
      'training-tool-techniques',
      'training-tool-drills',
      'training-tool-shot-timer',
      'training-tool-par-cadence',
      'training-tool-experiment',
      'training-tool-sight',
    ]) {
      await _scrollStartTo(tester, key);
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: key);
    }
    await _disposeApp(tester);
  });

  testWidgets('learning path opens its referenced lesson directly', (
    tester,
  ) async {
    final catalog = BuiltInTrainingContent.catalog;
    final path = catalog.learningPaths.firstWhere(
      (candidate) => candidate.entries.any(
        (entry) => entry.kind == LearningPathEntryKind.lesson,
      ),
    );
    final lessonEntry = path.entries.firstWhere(
      (entry) => entry.kind == LearningPathEntryKind.lesson,
    );
    final lesson = catalog.lessonByVersionedId(lessonEntry.versionedContentId)!;

    await tester.pumpWidget(
      _app(const TrainingToolsScreen(), database, repository),
    );
    await _pumpUi(tester);
    await _tapTool(tester, 'training-tool-learning-paths');

    final pathCard = find.byKey(ValueKey('learning-path-${path.id}'));
    await tester.scrollUntilVisible(pathCard, 220);
    await tester.tap(pathCard);
    await _pumpUi(tester);
    expect(find.byKey(const ValueKey('learning-path-detail')), findsOneWidget);
    expect(find.text(path.title), findsWidgets);

    final entry = find.byKey(ValueKey('learning-path-entry-${lessonEntry.id}'));
    await tester.scrollUntilVisible(entry, 220);
    await tester.tap(entry);
    await _pumpUi(tester);
    expect(find.text(lesson.title), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-step-title')),
      180,
    );
    expect(find.text('In één minuut'), findsOneWidget);
    await _disposeApp(tester);
  });

  testWidgets(
    'learning path resumes persisted progress and completed history is read only',
    (tester) async {
      final catalog = BuiltInTrainingContent.catalog;
      final source = catalog.learningPaths.first;
      final lesson = source.entries.firstWhere(
        (entry) => entry.kind == LearningPathEntryKind.lesson,
      );
      final historicalPath = LearningPathV2(
        id: 'widget-history-path',
        version: 1,
        title: 'Historisch widgetleerpad',
        shortDescription: 'Een immutable historisch leerpad.',
        discipline: source.discipline,
        estimatedMinutes: 5,
        entries: [
          LearningPathEntryV2(
            id: lesson.id,
            kind: lesson.kind,
            versionedContentId: lesson.versionedContentId,
          ),
        ],
        references: source.references,
        review: source.review,
      );
      final started = DateTime.utc(2026, 8, 10, 10);
      final historicalId = await repository.startLearningPathActivity(
        learningPathVersionedId: historicalPath.versionedId,
        learningPathSnapshot: historicalPath.toJson(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.updateLearningPathProgress(
        activityId: historicalId,
        completedEntryIds: [lesson.id],
      );
      await repository.completeLearningPath(
        activityId: historicalId,
        completedAtUtc: started.add(const Duration(minutes: 5)),
      );

      final activeId = await repository.startLearningPathActivity(
        learningPathVersionedId: source.versionedId,
        learningPathSnapshot: source.toJson(),
        startedAtUtc: started.add(const Duration(minutes: 10)),
        localUtcOffsetMinutes: 120,
      );
      await repository.updateLearningPathProgress(
        activityId: activeId,
        completedEntryIds: [lesson.id],
      );
      await repository.interruptLearningPath(activityId: activeId);

      await tester.pumpWidget(
        _app(const TrainingToolsScreen(), database, repository),
      );
      await _pumpUi(tester);
      final resume = find.byKey(
        ValueKey('training-resume-learning-path-$activeId'),
      );
      expect(resume, findsOneWidget);
      await tester.tap(resume);
      await _pumpUi(tester);
      expect(find.text(source.title), findsWidgets);
      expect(
        find.byKey(const ValueKey('resume-learning-path')),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 van ${source.entries.length}'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('resume-learning-path')));
      await _pumpUi(tester);
      final storedLesson = find.byKey(
        ValueKey('learning-path-entry-complete-${lesson.id}'),
      );
      await tester.scrollUntilVisible(storedLesson, 180);
      expect(tester.widget<Checkbox>(storedLesson).value, isTrue);
      expect(
        (await repository.getTrainingActivity(activeId))!.activity.status,
        StoredTrainingActivityStatus.draft.name,
      );
      await tester.pageBack();
      await _pumpUi(tester);
      await _selectDestination(tester, 4);
      final history = find.byKey(
        ValueKey('training-history-learning-path-$historicalId'),
      );
      await tester.scrollUntilVisible(history, 180);
      await tester.tap(history);
      await _pumpUi(tester);
      expect(find.text('Historisch widgetleerpad'), findsWidgets);
      expect(find.byKey(const ValueKey('start-learning-path')), findsNothing);
      expect(find.byKey(const ValueKey('resume-learning-path')), findsNothing);
      expect(
        find.byKey(ValueKey('learning-path-entry-complete-${lesson.id}')),
        findsNothing,
      );
      await _disposeApp(tester);
    },
  );

  testWidgets(
    'learning path history renders embedded lesson after catalog removal',
    (tester) async {
      final catalog = BuiltInTrainingContent.catalog;
      final sourcePath = catalog.learningPaths.firstWhere(
        (candidate) => candidate.entries.any(
          (entry) => entry.kind == LearningPathEntryKind.lesson,
        ),
      );
      final sourceEntry = sourcePath.entries.firstWhere(
        (entry) => entry.kind == LearningPathEntryKind.lesson,
      );
      final sourceLesson = catalog.lessonByVersionedId(
        sourceEntry.versionedContentId,
      )!;
      final embeddedLesson = TechniqueLessonV2.fromJson({
        ...sourceLesson.toJson(),
        'id': 'verwijderde-historische-les',
        'version': 41,
        'title': 'Opgeslagen historische les',
      });
      final embeddedEntry = LearningPathEntryV2(
        id: 'historical-lesson-entry',
        kind: LearningPathEntryKind.lesson,
        versionedContentId: embeddedLesson.versionedId,
      );
      final historicalPath = LearningPathV2(
        id: 'embedded-history-path',
        version: 3,
        title: 'Leerpad met opgeslagen inhoud',
        shortDescription: 'De catalogusversie bestaat niet meer.',
        discipline: sourcePath.discipline,
        estimatedMinutes: embeddedLesson.estimatedMinutes,
        entries: [embeddedEntry],
        references: sourcePath.references,
        review: sourcePath.review,
      );
      final started = DateTime.utc(2026, 8, 10, 9);
      await repository.createTrainingActivity(
        id: 'embedded-learning-path-history',
        kind: StoredTrainingActivityKind.learningPathV2,
        activitySchemaVersion: 2,
        status: StoredTrainingActivityStatus.completed,
        configuration: {
          'learningPathVersionedId': historicalPath.versionedId,
          'learningPath': historicalPath.toJson(),
          'entrySnapshots': [
            {
              'entryId': embeddedEntry.id,
              'kind': embeddedEntry.kind.name,
              'versionedContentId': embeddedEntry.versionedContentId,
              'content': embeddedLesson.toJson(),
            },
          ],
        },
        summary: {
          'completedEntryIds': [embeddedEntry.id],
          'currentEntryIndex': 1,
        },
        startedAtUtc: started,
        completedAtUtc: started.add(const Duration(minutes: 8)),
        localUtcOffsetMinutes: 120,
      );

      await tester.pumpWidget(
        _app(const TrainingToolsScreen(), database, repository),
      );
      await _pumpUi(tester);
      await _selectDestination(tester, 4);
      final history = find.byKey(
        const ValueKey(
          'training-history-learning-path-embedded-learning-path-history',
        ),
      );
      await tester.scrollUntilVisible(history, 180);
      await tester.tap(history);
      await _pumpUi(tester);

      expect(find.text('Leerpad met opgeslagen inhoud'), findsWidgets);
      expect(find.text('Opgeslagen historische les'), findsOneWidget);
      final entry = find.byKey(
        const ValueKey('learning-path-entry-historical-lesson-entry'),
      );
      await tester.scrollUntilVisible(entry, 180);
      await tester.tap(entry);
      await _pumpUi(tester);
      expect(find.text('Opgeslagen historische les'), findsWidgets);
      expect(
        find.byKey(const ValueKey('technique-step-title')),
        findsOneWidget,
      );
      await _disposeApp(tester);
    },
  );

  testWidgets('drill catalog applies every V2 filter and clears them', (
    tester,
  ) async {
    final target = BuiltInTrainingContent.catalog.drills.first;
    final targetTopic = target.measurements
        .firstWhere(
          (measurement) => measurement.role == TrainingMeasurementRole.primary,
        )
        .metric;
    await tester.pumpWidget(
      _app(const TrainingToolsScreen(), database, repository),
    );
    await _pumpUi(tester);
    await _tapTool(tester, 'training-tool-drills');

    await _openDrillFilters(tester);
    final search = await _scrollUntilVisibleByKey(
      tester,
      const ValueKey('training-drill-search'),
      const ValueKey('training-hub-drills'),
    );
    await tester.enterText(search, target.title);
    await _setCatalogFilter(
      tester,
      'training-drill-filter-discipline',
      target.discipline,
    );
    await _setCatalogFilter(
      tester,
      'training-drill-filter-level',
      target.skillLevel,
    );
    await _setCatalogFilter(tester, 'training-drill-filter-topic', targetTopic);
    await _setCatalogFilter(tester, 'training-drill-filter-mode', target.mode);
    await _setCatalogFilter(tester, 'training-drill-filter-time', 20);
    await _setCatalogFilter(
      tester,
      'training-drill-filter-ammunition',
      target.ammunitionBudget,
    );
    await _setCatalogFilter(
      tester,
      'training-drill-filter-review',
      target.review.coachReviewStatus,
    );

    expect(find.text('Filters (7 actief)'), findsOneWidget);
    final filteredTarget = await _scrollUntilVisibleByKey(
      tester,
      ValueKey('training-v2-drill-${target.id}'),
      const ValueKey('training-hub-drills'),
    );
    expect(filteredTarget, findsOneWidget);
    expect(find.text('1 drill'), findsOneWidget);

    await _setCatalogFilter(
      tester,
      'training-drill-filter-review',
      CoachReviewStatus.reviewed,
    );
    expect(find.text('0 drills'), findsOneWidget);
    expect(
      find.byKey(ValueKey('training-v2-drill-${target.id}')),
      findsNothing,
    );
    await _setCatalogFilter(
      tester,
      'training-drill-filter-review',
      target.review.coachReviewStatus,
    );

    expect(
      find.byKey(const ValueKey('training-drill-clear-filters')),
      findsOneWidget,
    );
    final clearFilters = find.byKey(
      const ValueKey('training-drill-clear-filters'),
    );
    await tester.ensureVisible(clearFilters);
    await _pumpUi(tester);
    await tester.tap(clearFilters);
    await _pumpUi(tester);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.textContaining('actief)'), findsNothing);
    final restoredTarget = await _scrollUntilVisibleByKey(
      tester,
      ValueKey('training-v2-drill-${target.id}'),
      const ValueKey('training-hub-drills'),
    );
    expect(restoredTarget, findsOneWidget);
    await _disposeApp(tester);
  });

  testWidgets('drill filters remain usable across responsive layouts', (
    tester,
  ) async {
    const cases = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 800), textScale: 1.3),
      (size: Size(412, 915), textScale: 2),
      (size: Size(640, 320), textScale: 2),
      (size: Size(1024, 768), textScale: 1),
    ];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final config in cases) {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          const TrainingToolsScreen(),
          database,
          repository,
          mediaQueryData: MediaQueryData(
            size: config.size,
            textScaler: TextScaler.linear(config.textScale),
          ),
        ),
      );
      await _pumpUi(tester);
      await _selectDestination(tester, 3);
      await _openDrillFilters(tester);

      for (final key in const [
        'training-drill-filter-discipline',
        'training-drill-filter-level',
        'training-drill-filter-topic',
        'training-drill-filter-mode',
        'training-drill-filter-time',
        'training-drill-filter-ammunition',
        'training-drill-filter-review',
      ]) {
        final field = await _scrollUntilVisibleByKey(
          tester,
          ValueKey(key),
          const ValueKey('training-hub-drills'),
        );
        expect(field, findsOneWidget, reason: '${config.size} @ $key');
        expect(
          tester.takeException(),
          isNull,
          reason: '${config.size} x ${config.textScale}: $key',
        );
      }
      await _disposeApp(tester);
    }
  });

  testWidgets('start exposes every active drill and resumes the actual plan', (
    tester,
  ) async {
    await _seedResumableActivities(repository);

    await tester.pumpWidget(
      _app(const TrainingToolsScreen(), database, repository),
    );
    await _pumpUi(tester);
    await _expectStartResumeItem(tester, 'resume-drill');
    await _expectStartResumeItem(tester, 'resume-drill-2');
    final planResume = await _expectStartResumeItem(tester, 'resume-plan');

    await tester.tap(planResume);
    await _pumpUi(tester);
    expect(find.text('Trainingsplan'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-generated-plan')), findsOneWidget);
    await _disposeApp(tester);
  });

  testWidgets('history exposes actual drill plan and legacy entries', (
    tester,
  ) async {
    await _seedResumableActivities(repository);
    await tester.pumpWidget(
      _app(const TrainingToolsScreen(), database, repository),
    );
    await _pumpUi(tester);

    await _selectDestination(tester, 4);
    expect(find.byKey(const ValueKey('training-hub-history')), findsOneWidget);
    await _expectHistoryItem(tester, 'resume-plan');
    await _expectHistoryItem(tester, 'resume-drill');
    await _expectHistoryItem(tester, 'resume-drill-2');
    await _expectHistoryItem(tester, 'legacy-drill');
    expect(find.text('Historische drill · alleen lezen'), findsOneWidget);
    await _disposeApp(tester);
  });

  testWidgets(
    'resume and history remain usable at 320 dp and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _seedResumableActivities(repository);

      await tester.pumpWidget(
        _app(
          const TrainingToolsScreen(),
          database,
          repository,
          mediaQueryData: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
        ),
      );
      await _pumpUi(tester);

      await _expectStartResumeItem(tester, 'resume-drill');
      await _expectStartResumeItem(tester, 'resume-drill-2');
      await _expectStartResumeItem(tester, 'resume-plan');
      expect(tester.takeException(), isNull);

      await _selectDestination(tester, 4);
      expect(
        find.byKey(const ValueKey('training-hub-history')),
        findsOneWidget,
      );
      await _expectHistoryItem(tester, 'resume-plan');
      await _expectHistoryItem(tester, 'resume-drill');
      await _expectHistoryItem(tester, 'resume-drill-2');
      await _expectHistoryItem(tester, 'legacy-drill');
      await _expectHistoryItem(tester, 'future-drill');
      expect(tester.takeException(), isNull);
      await _disposeApp(tester);
    },
  );

  testWidgets(
    'history opens completed legacy and malformed activities read only',
    (tester) async {
      await _seedResumableActivities(repository);
      await tester.pumpWidget(
        _app(const TrainingToolsScreen(), database, repository),
      );
      await _pumpUi(tester);
      await _selectDestination(tester, 4);

      for (final entry in const <(String, String)>[
        ('completed-drill', 'Voltooide drill'),
        ('legacy-drill', 'Historische drill'),
        ('malformed-drill', 'Beschadigde drill'),
        ('malformed-plan', 'Beschadigd plan'),
        ('future-drill', 'Toekomstige drill'),
      ]) {
        final item = await _expectHistoryItem(tester, entry.$1);
        expect(
          find.descendant(of: item, matching: find.byIcon(Icons.play_arrow)),
          findsNothing,
          reason: entry.$1,
        );
        expect(
          find.descendant(of: item, matching: find.byIcon(Icons.chevron_right)),
          findsOneWidget,
          reason: entry.$1,
        );
        await tester.tap(item);
        await _pumpUi(tester);
        expect(find.text(entry.$2), findsWidgets);
        expect(
          find.byKey(const ValueKey('guided-drill-runner-list')),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: entry.$1);
        await tester.pageBack();
        await _pumpUi(tester);
      }
      await _disposeApp(tester);
    },
  );

  testWidgets('hub remains usable at 320 dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        const TrainingToolsScreen(),
        database,
        repository,
        mediaQueryData: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Leren & oefenen'), findsOneWidget);
    await _scrollStartTo(tester, 'training-tool-planner');
    expect(find.byKey(const ValueKey('training-tool-planner')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapTool(tester, 'training-tool-techniques');
    expect(
      find.byKey(const ValueKey('technique-library-list')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _disposeApp(tester);
  });
}

void _expectFiveAdaptiveDestinations(WidgetTester tester) {
  final bar = find.byKey(const ValueKey('training-hub-navigation-bar'));
  final rail = find.byKey(const ValueKey('training-hub-navigation-rail'));
  expect(bar.evaluate().isNotEmpty || rail.evaluate().isNotEmpty, isTrue);
  if (bar.evaluate().isNotEmpty) {
    expect(tester.widget<NavigationBar>(bar).destinations, hasLength(5));
  } else {
    expect(tester.widget<NavigationRail>(rail).destinations, hasLength(5));
  }
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _selectDestination(WidgetTester tester, int index) async {
  final bar = find.byKey(const ValueKey('training-hub-navigation-bar'));
  if (bar.evaluate().isNotEmpty) {
    tester.widget<NavigationBar>(bar).onDestinationSelected?.call(index);
  } else {
    final rail = find.byKey(const ValueKey('training-hub-navigation-rail'));
    tester.widget<NavigationRail>(rail).onDestinationSelected?.call(index);
  }
  await _pumpUi(tester);
}

Future<void> _scrollStartTo(WidgetTester tester, String key) async {
  await _scrollUntilVisibleByKey(
    tester,
    ValueKey(key),
    const ValueKey('training-hub-start'),
  );
}

Future<void> _tapTool(WidgetTester tester, String key) async {
  await _scrollStartTo(tester, key);
  final finder = find.byKey(ValueKey(key));
  await tester.tap(finder);
  await _pumpUi(tester);
}

Future<void> _openDrillFilters(WidgetTester tester) async {
  final finder = await _scrollUntilVisibleByKey(
    tester,
    const ValueKey('training-drill-filters'),
    const ValueKey('training-hub-drills'),
  );
  await tester.tap(finder);
  await _pumpUi(tester);
}

Future<void> _setCatalogFilter<T>(
  WidgetTester tester,
  String fieldKey,
  T? value,
) async {
  final field = await _scrollUntilVisibleByKey(
    tester,
    ValueKey(fieldKey),
    const ValueKey('training-hub-drills'),
  );
  final dropdown = find.descendant(
    of: field,
    matching: find.byType(DropdownButton<T>),
  );
  expect(dropdown, findsOneWidget, reason: fieldKey);
  tester.widget<DropdownButton<T>>(dropdown).onChanged?.call(value);
  await _pumpUi(tester);
}

Future<Finder> _expectStartResumeItem(
  WidgetTester tester,
  String activityId,
) async {
  await _jumpToStart(tester, const ValueKey('training-hub-start'));
  final finder = await _scrollUntilVisibleByKey(
    tester,
    ValueKey('training-resume-$activityId'),
    const ValueKey('training-hub-start'),
  );
  expect(finder, findsOneWidget);
  expect(tester.takeException(), isNull, reason: activityId);
  return finder;
}

Future<Finder> _expectHistoryItem(
  WidgetTester tester,
  String activityId,
) async {
  await _jumpToStart(tester, const ValueKey('training-hub-history'));
  final finder = await _scrollUntilVisibleByKey(
    tester,
    ValueKey('training-history-activity-$activityId'),
    const ValueKey('training-hub-history'),
  );
  expect(finder, findsOneWidget);
  expect(tester.takeException(), isNull, reason: activityId);
  return finder;
}

Future<void> _jumpToStart(WidgetTester tester, Key listKey) async {
  final list = find.byKey(listKey);
  expect(list, findsOneWidget);
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final state = tester.state<ScrollableState>(scrollable);
  state.position.jumpTo(state.position.minScrollExtent);
  await _pumpUi(tester);
}

Future<Finder> _scrollUntilVisibleByKey(
  WidgetTester tester,
  Key itemKey,
  Key scrollableKey,
) async {
  final finder = find.byKey(itemKey);
  final allFinder = find.byKey(itemKey, skipOffstage: false);
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (allFinder.evaluate().isNotEmpty) {
      await tester.ensureVisible(allFinder);
      await _pumpUi(tester);
      return find.byKey(itemKey);
    }
    final scrollable = find.byKey(scrollableKey);
    expect(scrollable, findsOneWidget, reason: '$scrollableKey voor $itemKey');
    await tester.drag(scrollable, const Offset(0, -180));
    await _pumpUi(tester);
  }
  expect(finder, findsOneWidget);
  return finder;
}

Widget _app(
  Widget home,
  AppDatabase database,
  ShootingRepository repository, {
  MediaQueryData? mediaQueryData,
}) => ProviderScope(
  overrides: [
    databaseProvider.overrideWithValue(database),
    repositoryProvider.overrideWithValue(repository),
    timerPresetsProvider.overrideWith((ref) => Stream.value(const [])),
    acousticCalibrationProfilesProvider.overrideWith(
      (ref) => Stream.value(const []),
    ),
  ],
  child: MaterialApp(
    theme: ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F6F8F)),
      useMaterial3: true,
    ),
    builder: mediaQueryData == null
        ? null
        : (context, child) => MediaQuery(
            data: mediaQueryData,
            child: child ?? const SizedBox.shrink(),
          ),
    home: home,
  ),
);

Future<void> _seedResumableActivities(ShootingRepository repository) async {
  final catalog = BuiltInTrainingContent.catalog;
  final drill = catalog.drills.first;
  final plan = const DeterministicDrillPlanner().generate(
    durationMinutes: 30,
    discipline: TrainingDiscipline.precisionPistol,
    skillLevel: TrainingSkillLevel.foundation,
    focus: TrainingPlanFocus.fundamentals,
    ammunitionBudget: 100,
    drills: catalog.drills,
    learningPaths: catalog.learningPaths,
  );
  final now = DateTime.utc(2026, 8, 10, 10);
  await repository.createTrainingActivity(
    id: 'resume-drill',
    kind: StoredTrainingActivityKind.guidedDrillV2,
    activitySchemaVersion: 2,
    status: StoredTrainingActivityStatus.interrupted,
    configuration: {
      'drillVersionedId': drill.versionedId,
      'drill': drill.toJson(),
    },
    summary: const {
      'setupConfirmed': false,
      'safetyConfirmed': false,
      'acknowledgedPhaseIds': <String>[],
      'timerActivityIds': <String, String>{},
      'phaseReflections': <String, String>{},
    },
    startedAtUtc: now,
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'resume-drill-2',
    kind: StoredTrainingActivityKind.guidedDrillV2,
    activitySchemaVersion: 2,
    status: StoredTrainingActivityStatus.interrupted,
    configuration: {
      'drillVersionedId': drill.versionedId,
      'drill': drill.toJson(),
    },
    summary: const {
      'setupConfirmed': false,
      'safetyConfirmed': false,
      'acknowledgedPhaseIds': <String>[],
      'timerActivityIds': <String, String>{},
      'phaseReflections': <String, String>{},
    },
    startedAtUtc: now.add(const Duration(minutes: 2)),
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'resume-plan',
    kind: StoredTrainingActivityKind.trainingPlan,
    status: StoredTrainingActivityStatus.interrupted,
    configuration: {'planId': plan.id, 'plan': plan.toJson()},
    summary: const {
      'completedSlotIndexes': <int>[],
      'completedStepIds': <String>[],
      'guidedDrillActivityIds': <String, String>{},
      'currentStepIndex': 0,
    },
    startedAtUtc: now.add(const Duration(minutes: 1)),
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'legacy-drill',
    kind: StoredTrainingActivityKind.drill,
    configuration: const {
      'drillVersionedId': 'legacy@1',
      'drill': {'name': 'Historische drill'},
    },
    startedAtUtc: now.subtract(const Duration(days: 1)),
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'completed-drill',
    kind: StoredTrainingActivityKind.guidedDrillV2,
    activitySchemaVersion: 2,
    status: StoredTrainingActivityStatus.completed,
    configuration: {
      'drillVersionedId': drill.versionedId,
      'drill': {...drill.toJson(), 'title': 'Voltooide drill'},
    },
    startedAtUtc: now.subtract(const Duration(hours: 1)),
    completedAtUtc: now.subtract(const Duration(minutes: 30)),
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'malformed-drill',
    kind: StoredTrainingActivityKind.guidedDrillV2,
    activitySchemaVersion: 2,
    status: StoredTrainingActivityStatus.interrupted,
    configuration: const {
      'drillVersionedId': 'broken-drill@2',
      'drill': {'title': 'Beschadigde drill'},
    },
    startedAtUtc: now.subtract(const Duration(hours: 2)),
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'malformed-plan',
    kind: StoredTrainingActivityKind.trainingPlan,
    status: StoredTrainingActivityStatus.interrupted,
    configuration: const {
      'planId': 'broken-plan',
      'plan': {'title': 'Beschadigd plan'},
    },
    startedAtUtc: now.subtract(const Duration(hours: 3)),
    localUtcOffsetMinutes: 120,
  );
  await repository.createTrainingActivity(
    id: 'future-drill',
    kind: StoredTrainingActivityKind.guidedDrillV2,
    activitySchemaVersion: 999,
    status: StoredTrainingActivityStatus.interrupted,
    configuration: {
      'drillVersionedId': drill.versionedId,
      'drill': {...drill.toJson(), 'title': 'Toekomstige drill'},
    },
    startedAtUtc: now.subtract(const Duration(hours: 4)),
    localUtcOffsetMinutes: 120,
  );
}
