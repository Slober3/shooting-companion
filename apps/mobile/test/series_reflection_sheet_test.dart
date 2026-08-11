import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/coaching_preferences_repository.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/session/series_reflection_sheet.dart';
import 'package:shooting_companion/features/settings/settings_screen.dart';

void main() {
  testWidgets('quick quality choice closes with an empty context set', (
    tester,
  ) async {
    Future<SeriesReflectionDraft?>? result;
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        result = showSeriesReflectionSheet(context: context);
      },
    );

    await tester.tap(find.text('Reflectie openen'));
    await tester.pumpAndSettle();
    expect(find.text('Hoe voelde deze reeks?'), findsOneWidget);

    await tester.tap(find.text('Goed'));
    await tester.pumpAndSettle();

    final draft = await result;
    expect(draft?.perceivedQuality, PerceivedQuality.good);
    expect(draft?.contextTags, isEmpty);
  });

  testWidgets('extra context accepts at most three tags', (tester) async {
    Future<SeriesReflectionDraft?>? result;
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        result = showSeriesReflectionSheet(context: context);
      },
    );

    await tester.tap(find.text('Reflectie openen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meer context'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neutraal'));
    await tester.tap(find.text('Richtbeeld'));
    await tester.tap(find.text('Trekker'));
    await tester.tap(find.text('Grip/houding'));
    await tester.tap(find.text('Ademhaling'));
    await tester.pump();

    expect(find.text('Kies maximaal drie contexttags.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Bewaren'));
    await tester.pumpAndSettle();

    final draft = await result;
    expect(draft?.perceivedQuality, PerceivedQuality.neutral);
    expect(draft?.contextTags, {
      ReflectionContextTag.sightPicture,
      ReflectionContextTag.trigger,
      ReflectionContextTag.gripOrPosition,
    });
  });

  testWidgets('overslaan closes without creating a reflection draft', (
    tester,
  ) async {
    Future<SeriesReflectionDraft?>? result;
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        result = showSeriesReflectionSheet(context: context);
      },
    );

    await tester.tap(find.text('Reflectie openen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reflection-skip')));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('optional prompt stays closed while coach mode is disabled', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    Future<SeriesReflectionPromptResult>? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton(
                onPressed: () {
                  result = maybeShowSeriesReflectionPrompt(
                    context: context,
                    ref: ref,
                    seriesId: 'unused-while-disabled',
                  );
                },
                child: const Text('Reflectie vragen'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reflectie vragen'));
    await tester.pumpAndSettle();

    expect(await result, SeriesReflectionPromptResult.disabled);
    expect(find.text('Korte reflectie'), findsNothing);
  });

  testWidgets(
    'optional prompt persists reflection only when coach mode is on',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = ShootingRepository(database);
      await repository.seedDefaults();
      final quick = await repository.startQuickSession();
      final preferences = CoachingPreferencesRepository(database);
      await preferences.setCoachMode(true);
      Future<SeriesReflectionPromptResult>? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => FilledButton(
                  onPressed: () {
                    result = maybeShowSeriesReflectionPrompt(
                      context: context,
                      ref: ref,
                      seriesId: quick.draftSeriesId,
                    );
                  },
                  child: const Text('Reflectie vragen'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reflectie vragen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moeilijk'));
      await tester.pumpAndSettle();

      expect(await result, SeriesReflectionPromptResult.saved);
      final reflection = await (database.select(
        database.seriesReflections,
      )..where((row) => row.seriesId.equals(quick.draftSeriesId))).getSingle();
      expect(reflection.perceivedQuality, PerceivedQuality.difficult.name);
      expect(reflection.contextTagsJson, '[]');
    },
  );

  testWidgets('series card shows and edits the stored self-evaluation', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final quick = await repository.startQuickSession();
    await repository.saveSeriesReflection(
      seriesId: quick.draftSeriesId,
      perceivedQuality: PerceivedQuality.difficult,
      contextTags: const {
        ReflectionContextTag.trigger,
        ReflectionContextTag.followThrough,
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Scaffold(
            body: SeriesReflectionCard(seriesId: quick.draftSeriesId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zelfevaluatie'), findsOneWidget);
    expect(find.text('Moeilijk'), findsOneWidget);
    expect(find.text('Trekker'), findsOneWidget);
    expect(find.text('Follow-through'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-series-reflection')));
    await tester.pumpAndSettle();
    expect(find.text('Korte reflectie'), findsOneWidget);
    expect(find.text('Context (maximaal 3)'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const ValueKey('reflection-tag-trigger')),
          )
          .selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('settings toggles coach mode as an offline preference', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final preferences = CoachingPreferencesRepository(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coachmodus'), findsOneWidget);
    expect(await preferences.readCoachMode(), isFalse);
    await tester.tap(find.byKey(const ValueKey('coach-mode-toggle')));
    await tester.pumpAndSettle();

    expect(await preferences.readCoachMode(), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  required void Function(BuildContext context) onOpen,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () => onOpen(context),
          child: const Text('Reflectie openen'),
        ),
      ),
    ),
  ),
);
