import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/history/history_screen.dart';
import 'package:shooting_companion/features/session/active_session_screen.dart';
import 'package:shooting_companion/features/today/today_screen.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
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

  test(
    'session list aggregate does not multiply scores by photo joins',
    () async {
      final quick = await repository.startQuickSession();
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [
          ShotImpact(id: 'double', xMm: 0, yMm: 0, multiplicity: 2),
          ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
        ],
      );
      await repository.confirmSeries(quick.draftSeriesId);
      await repository.attachImage(
        NewImageAsset(
          id: 'primary',
          sessionId: quick.sessionId,
          seriesId: quick.draftSeriesId,
          role: ImageRole.primaryScoringPhoto,
          path: 'primary.jpg',
          sha256: 'primary-hash',
          width: 2000,
          height: 2000,
          sizeBytes: 10,
        ),
      );
      await repository.attachImage(
        NewImageAsset(
          id: 'confirmed-attachment',
          sessionId: quick.sessionId,
          seriesId: quick.draftSeriesId,
          role: ImageRole.attachment,
          path: 'confirmed.jpg',
          sha256: 'confirmed-hash',
          width: 2000,
          height: 2000,
          sizeBytes: 10,
        ),
      );

      final draftId = await repository.createOrResumeDraftSeries(
        quick.sessionId,
      );
      await repository.saveSeriesDraft(
        seriesId: draftId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'draft-shot', xMm: 0, yMm: 0)],
      );
      await repository.attachImage(
        NewImageAsset(
          id: 'draft-photo',
          sessionId: quick.sessionId,
          seriesId: draftId,
          role: ImageRole.attachment,
          path: 'draft.jpg',
          sha256: 'draft-hash',
          width: 2000,
          height: 2000,
          sizeBytes: 10,
        ),
      );
      await repository.attachImage(
        NewImageAsset(
          id: 'session-photo',
          sessionId: quick.sessionId,
          role: ImageRole.attachment,
          path: 'session.jpg',
          sha256: 'session-hash',
          width: 2000,
          height: 2000,
          sizeBytes: 10,
        ),
      );

      final item = (await repository.watchSessionListItems().first).single;
      expect(item.confirmedSeriesCount, 1);
      expect(item.shotCount, 3);
      expect(item.totalScore, 20);
      expect(item.maximumPossibleScore, 30);
      expect(item.photoCount, 4);
      expect(item.draftSeriesId, draftId);
      expect(item.draftShotCount, 1);
      expect(item.draftPhotoCount, 1);
      expect(item.thumbnailPath, 'primary.jpg');
    },
  );

  test('meaningful draft must be resolved before session completion', () async {
    final quick = await repository.startQuickSession();
    await repository.saveSeriesDraft(
      seriesId: quick.draftSeriesId,
      target: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
      projectileDiameterMm: 5.6,
      impacts: const [ShotImpact(id: 'shot', xMm: 0, yMm: 0)],
    );

    await expectLater(
      repository.completeSession(quick.sessionId),
      throwsA(
        isA<UnresolvedDraftException>()
            .having((error) => error.shotCount, 'shotCount', 1)
            .having((error) => error.seriesId, 'seriesId', quick.draftSeriesId),
      ),
    );

    final detail = await repository.getSessionDetail(quick.sessionId);
    expect(detail!.session.status, SessionStatus.active.name);
    expect(detail.draftSeries!.id, quick.draftSeriesId);
    expect(detail.confirmedSeries, isEmpty);
  });

  test('draft note is meaningful and cannot be silently discarded', () async {
    final quick = await repository.startQuickSession();
    await repository.saveSeriesDraft(
      seriesId: quick.draftSeriesId,
      target: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
      projectileDiameterMm: 5.6,
      impacts: const [],
      notes: 'Pas later punten toevoegen',
    );

    final item = (await repository.watchSessionListItems().first).single;
    expect(item.draftHasNotes, isTrue);
    expect(item.hasMeaningfulDraft, isTrue);
    await expectLater(
      repository.completeSession(quick.sessionId),
      throwsA(
        isA<UnresolvedDraftException>()
            .having((error) => error.hasNotes, 'hasNotes', isTrue)
            .having((error) => error.shotCount, 'shotCount', 0),
      ),
    );

    final detail = await repository.getSessionDetail(quick.sessionId);
    expect(detail!.session.status, SessionStatus.active.name);
    expect(detail.draftSeries!.notes, 'Pas later punten toevoegen');
  });

  test('settings-only draft cannot be silently discarded', () async {
    final quick = await repository.startQuickSession();
    await repository.saveSeriesDraft(
      seriesId: quick.draftSeriesId,
      target: IssfTargetProfiles.rapidFire25m,
      distanceMeters: 50,
      projectileDiameterMm: 9.03,
      impacts: const [],
    );

    final item = (await repository.watchSessionListItems().first).single;
    expect(item.draftWasEdited, isTrue);
    expect(item.hasMeaningfulDraft, isTrue);
    await expectLater(
      repository.completeSession(quick.sessionId),
      throwsA(
        isA<UnresolvedDraftException>()
            .having((error) => error.wasEdited, 'wasEdited', isTrue)
            .having((error) => error.shotCount, 'shotCount', 0),
      ),
    );

    final detail = await repository.getSessionDetail(quick.sessionId);
    expect(detail!.session.status, SessionStatus.active.name);
    expect(detail.draftSeries!.distanceMeters, 50);
    expect(
      detail.draftSeries!.targetProfileVersionedId,
      IssfTargetProfiles.rapidFire25m.versionedId,
    );
  });

  test(
    'save, confirm and complete is atomic and double completion is safe',
    () async {
      final quick = await repository.startQuickSession();
      final result = await repository.saveConfirmAndCompleteSeries(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [
          ShotImpact(id: 'center', xMm: 0, yMm: 0, multiplicity: 2),
          ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
        ],
        notes: 'Afgerond in één actie',
      );

      expect(result.outcome, SessionCompletionOutcome.completed);
      expect(result.confirmedDraftId, quick.draftSeriesId);
      final detail = await repository.getSessionDetail(quick.sessionId);
      expect(detail!.session.status, SessionStatus.completed.name);
      expect(detail.draftSeries, isNull);
      expect(detail.confirmedSeries.single.shotCount, 3);
      expect(detail.confirmedSeries.single.totalScore, 20);
      expect(detail.confirmedSeries.single.maximumPossibleScore, 30);

      final second = await repository.completeSession(quick.sessionId);
      expect(second.outcome, SessionCompletionOutcome.alreadyCompleted);
      expect(
        (await repository.getSessionDetail(quick.sessionId))!.seriesCount,
        1,
      );
    },
  );

  test(
    'empty completion deletes once and repeated completion is idempotent',
    () async {
      final quick = await repository.startQuickSession();

      final first = await repository.completeSession(quick.sessionId);
      final second = await repository.completeSession(quick.sessionId);

      expect(first.outcome, SessionCompletionOutcome.deletedEmpty);
      expect(second.outcome, SessionCompletionOutcome.notFound);
      expect(await repository.getSessionDetail(quick.sessionId), isNull);
    },
  );

  test('session details keep an otherwise empty session', () async {
    final quick = await repository.startQuickSession();
    await repository.updateSessionDetails(
      sessionId: quick.sessionId,
      startedAtUtc: DateTime.now().toUtc(),
      localUtcOffsetMinutes: 120,
      rangeId: null,
      trainingGoal: null,
      conditions: null,
      notes: 'Later aanvullen',
    );

    final result = await repository.completeSession(quick.sessionId);

    expect(result.outcome, SessionCompletionOutcome.completed);
    final detail = await repository.getSessionDetail(quick.sessionId);
    expect(detail, isNotNull);
    expect(detail!.session.status, SessionStatus.completed.name);
    expect(detail.session.notes, 'Later aanvullen');
    expect(detail.confirmedSeries, isEmpty);
  });

  test('session-only photo is counted and keeps an empty session', () async {
    final quick = await repository.startQuickSession();
    await repository.attachImage(
      NewImageAsset(
        id: 'session-photo',
        sessionId: quick.sessionId,
        role: ImageRole.attachment,
        path: 'session-photo.jpg',
        sha256: 'session-photo-hash',
        width: 1200,
        height: 900,
        sizeBytes: 10,
      ),
    );

    final item = (await repository.watchSessionListItems().first).single;
    expect(item.photoCount, 1);
    expect(item.sessionPhotoCount, 1);
    final result = await repository.completeSession(quick.sessionId);
    expect(result.outcome, SessionCompletionOutcome.completed);
    expect(await repository.getSessionDetail(quick.sessionId), isNotNull);
  });

  test(
    'realignment changes only photo impacts and updates the score atomically',
    () async {
      final quick = await repository.startQuickSession();
      await repository.attachImage(
        NewImageAsset(
          id: 'score-photo',
          sessionId: quick.sessionId,
          seriesId: quick.draftSeriesId,
          role: ImageRole.primaryScoringPhoto,
          path: 'score-photo.jpg',
          sha256: 'score-photo-hash',
          width: 2000,
          height: 2000,
          sizeBytes: 10,
        ),
      );
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [
          ShotImpact(
            id: 'photo-impact',
            xMm: 300,
            yMm: 0,
            sourceImageId: 'score-photo',
            imageXNormalized: 0.5,
            imageYNormalized: 0.5,
          ),
          ShotImpact(id: 'manual-impact', xMm: 30, yMm: 0),
        ],
      );

      final alignment = _alignment('score-photo');
      final beforeRealignment = await repository.getSeriesDetail(
        quick.draftSeriesId,
      );
      final storedManualImpact = beforeRealignment!.impacts
          .singleWhere((impact) => impact.id == 'manual-impact')
          .asDomain;
      await repository.realignSeriesPhoto(
        seriesId: quick.draftSeriesId,
        alignment: alignment,
        target: IssfTargetProfiles.precision25m50m,
        projectileDiameterMm: 5.6,
        resultingImpacts: [
          const ShotImpact(
            id: 'photo-impact',
            xMm: 0,
            yMm: 0,
            sourceImageId: 'score-photo',
            imageXNormalized: 0.5,
            imageYNormalized: 0.5,
          ),
          storedManualImpact,
        ],
      );

      var detail = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(
        detail!.photoAlignment!.algorithmVersion,
        geo.manualHomographyV2AlgorithmVersion,
      );
      expect(
        detail.impacts.singleWhere((impact) => impact.id == 'photo-impact').xMm,
        0,
      );
      expect(
        detail.impacts
            .singleWhere((impact) => impact.id == 'manual-impact')
            .xMm,
        30,
      );
      expect(detail.series.shotCount, 2);
      expect(detail.series.maximumPossibleScore, 20);
      expect(detail.series.totalScore, greaterThan(10));

      await expectLater(
        repository.realignSeriesPhoto(
          seriesId: quick.draftSeriesId,
          alignment: _alignment('score-photo'),
          target: IssfTargetProfiles.precision25m50m,
          projectileDiameterMm: 5.6,
          resultingImpacts: [
            const ShotImpact(
              id: 'photo-impact',
              xMm: 1,
              yMm: 0,
              sourceImageId: 'score-photo',
              imageXNormalized: 0.5,
              imageYNormalized: 0.5,
            ),
            storedManualImpact.copyWith(xMm: 1),
          ],
        ),
        throwsStateError,
      );
      detail = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(
        detail!.photoAlignment!.algorithmVersion,
        geo.manualHomographyV2AlgorithmVersion,
      );
      expect(
        detail.impacts.singleWhere((impact) => impact.id == 'photo-impact').xMm,
        0,
      );
      expect(
        detail.impacts
            .singleWhere((impact) => impact.id == 'manual-impact')
            .xMm,
        30,
      );
    },
  );

  test(
    'realignment uses original image coordinates across quarter-turn changes',
    () async {
      final quick = await repository.startQuickSession();
      await repository.attachImage(
        NewImageAsset(
          id: 'rotated-photo',
          sessionId: quick.sessionId,
          seriesId: quick.draftSeriesId,
          role: ImageRole.primaryScoringPhoto,
          path: 'rotated-photo.jpg',
          sha256: 'rotated-photo-hash',
          width: 2400,
          height: 1600,
          sizeBytes: 10,
        ),
      );
      await repository.savePhotoAlignment(_alignment('rotated-photo'));
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [
          ShotImpact(
            id: 'rotated-impact',
            xMm: -171.875,
            yMm: 0,
            sourceImageId: 'rotated-photo',
            imageXNormalized: 0.25,
            imageYNormalized: 0.5,
          ),
          ShotImpact(id: 'unchanged-manual', xMm: 10, yMm: 20),
        ],
      );
      final storedBefore = await (database.select(
        database.shotImpacts,
      )..where((row) => row.id.equals('unchanged-manual'))).getSingle();
      final detailBefore = await repository.getSeriesDetail(
        quick.draftSeriesId,
      );
      final inputs = [
        detailBefore!.impacts
            .singleWhere((impact) => impact.id == 'rotated-impact')
            .asDomain
            .copyWith(xMm: 0, yMm: -171.875),
        detailBefore.impacts
            .singleWhere((impact) => impact.id == 'unchanged-manual')
            .asDomain,
      ];

      await repository.realignSeriesPhoto(
        seriesId: quick.draftSeriesId,
        alignment: _alignment('rotated-photo', rotationQuarterTurns: 1),
        target: IssfTargetProfiles.precision25m50m,
        projectileDiameterMm: 5.6,
        resultingImpacts: inputs,
      );

      final detail = await repository.getSeriesDetail(quick.draftSeriesId);
      final rotated = detail!.impacts.singleWhere(
        (impact) => impact.id == 'rotated-impact',
      );
      expect(rotated.imageXNormalized, 0.25);
      expect(rotated.imageYNormalized, 0.5);
      expect(rotated.xMm, closeTo(0, 1e-9));
      expect(rotated.yMm, closeTo(-171.875, 1e-9));
      expect(detail.photoAlignment!.rotationQuarterTurns, 1);
      expect(detail.photoAlignment!.alignmentMode, 'fullCard');
      expect(detail.photoAlignment!.planarityStatus, 'accepted');
      expect(detail.photoAlignment!.confirmedAtUtc, isNotNull);

      final storedAfter = await (database.select(
        database.shotImpacts,
      )..where((row) => row.id.equals('unchanged-manual'))).getSingle();
      expect(storedAfter.toJson(), storedBefore.toJson());
    },
  );

  test(
    'realignment promotes an attachment and demotes the old primary atomically',
    () async {
      final quick = await repository.startQuickSession();
      for (final image in const [
        (id: 'old-primary', role: ImageRole.primaryScoringPhoto),
        (id: 'new-primary', role: ImageRole.attachment),
      ]) {
        await repository.attachImage(
          NewImageAsset(
            id: image.id,
            sessionId: quick.sessionId,
            seriesId: quick.draftSeriesId,
            role: image.role,
            path: '${image.id}.jpg',
            sha256: '${image.id}-hash',
            width: 2000,
            height: 1500,
            sizeBytes: 10,
          ),
        );
      }
      await repository.savePhotoAlignment(_alignment('old-primary'));

      await repository.realignSeriesPhoto(
        seriesId: quick.draftSeriesId,
        alignment: _alignment('new-primary'),
        target: IssfTargetProfiles.precision25m50m,
        projectileDiameterMm: 5.6,
        resultingImpacts: const [],
      );

      final detail = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(detail!.primaryImage!.id, 'new-primary');
      expect(detail.photoAlignment!.imageId, 'new-primary');
      expect(
        detail.photoAlignment!.algorithmVersion,
        geo.manualHomographyV2AlgorithmVersion,
      );
      expect(
        detail.images.singleWhere((image) => image.id == 'old-primary').role,
        ImageRole.attachment.name,
      );
      final staleAlignment = await database
          .customSelect(
            "SELECT image_id FROM photo_alignments WHERE image_id = 'old-primary'",
          )
          .get();
      expect(staleAlignment, isEmpty);
    },
  );

  test('rejected alignment quality is never persisted', () async {
    final quick = await repository.startQuickSession();
    await repository.attachImage(
      NewImageAsset(
        id: 'rejected-photo',
        sessionId: quick.sessionId,
        seriesId: quick.draftSeriesId,
        role: ImageRole.primaryScoringPhoto,
        path: 'rejected-photo.jpg',
        sha256: 'rejected-photo-hash',
        width: 2000,
        height: 2000,
        sizeBytes: 10,
      ),
    );

    await expectLater(
      repository.savePhotoAlignment(
        _alignment('rejected-photo', planarityStatus: 'rejected'),
      ),
      throwsStateError,
    );
    expect(await database.select(database.photoAlignments).get(), isEmpty);
  });

  test('failed attachment promotion rolls every media change back', () async {
    final quick = await repository.startQuickSession();
    for (final image in const [
      (id: 'rollback-old', role: ImageRole.primaryScoringPhoto),
      (id: 'rollback-new', role: ImageRole.attachment),
    ]) {
      await repository.attachImage(
        NewImageAsset(
          id: image.id,
          sessionId: quick.sessionId,
          seriesId: quick.draftSeriesId,
          role: image.role,
          path: '${image.id}.jpg',
          sha256: '${image.id}-hash',
          width: 2000,
          height: 1500,
          sizeBytes: 10,
        ),
      );
    }
    await repository.savePhotoAlignment(_alignment('rollback-old'));
    await database.customStatement('''
      CREATE TRIGGER reject_new_alignment
      BEFORE INSERT ON photo_alignments
      WHEN NEW.image_id = 'rollback-new'
      BEGIN
        SELECT RAISE(ABORT, 'forced alignment failure');
      END
    ''');

    await expectLater(
      repository.realignSeriesPhoto(
        seriesId: quick.draftSeriesId,
        alignment: _alignment('rollback-new'),
        target: IssfTargetProfiles.precision25m50m,
        projectileDiameterMm: 5.6,
        resultingImpacts: const [],
      ),
      throwsA(anything),
    );

    final detail = await repository.getSeriesDetail(quick.draftSeriesId);
    expect(detail!.primaryImage!.id, 'rollback-old');
    expect(detail.photoAlignment!.imageId, 'rollback-old');
    expect(
      detail.photoAlignment!.algorithmVersion,
      geo.manualHomographyV2AlgorithmVersion,
    );
    expect(
      detail.images.singleWhere((image) => image.id == 'rollback-new').role,
      ImageRole.attachment.name,
    );
    final newAlignment = await database
        .customSelect(
          "SELECT image_id FROM photo_alignments WHERE image_id = 'rollback-new'",
        )
        .get();
    expect(newAlignment, isEmpty);
  });

  testWidgets('Logboek filter sheet applies status and date filters', (
    tester,
  ) async {
    final completed = await _createScoredSession(repository);
    final oldDate = DateTime.now().toUtc().subtract(const Duration(days: 400));
    await repository.updateSessionDetails(
      sessionId: completed.sessionId,
      startedAtUtc: oldDate,
      localUtcOffsetMinutes: 120,
      rangeId: null,
      trainingGoal: 'Oude sessie',
      conditions: null,
      notes: null,
    );
    await repository.completeSession(completed.sessionId);
    final active = await repository.startQuickSession();
    await repository.updateSessionDetails(
      sessionId: active.sessionId,
      startedAtUtc: DateTime.now().toUtc(),
      localUtcOffsetMinutes: 120,
      rangeId: null,
      trainingGoal: 'Actieve sessie',
      conditions: null,
      notes: null,
    );

    await tester.pumpWidget(_testApp(database, const HistoryScreen()));
    await _pumpUi(tester);
    expect(find.text('Oude sessie'), findsOneWidget);
    expect(find.text('Actieve sessie'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await _pumpUi(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Beëindigd'));
    await tester.tap(find.text('Toepassen'));
    await _pumpUi(tester);
    expect(find.text('Status: Beëindigd'), findsOneWidget);
    expect(find.text('Oude sessie'), findsOneWidget);
    expect(find.text('Actieve sessie'), findsNothing);

    await tester.tap(find.byKey(const Key('history-filter-button')));
    await _pumpUi(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Alle'));
    await tester.tap(find.widgetWithText(ChoiceChip, '30 dagen'));
    await tester.tap(find.text('Toepassen'));
    await _pumpUi(tester);
    expect(find.text('30 dagen'), findsOneWidget);
    expect(find.text('Actieve sessie'), findsOneWidget);
    expect(find.text('Oude sessie'), findsNothing);
    await _disposeTestTree(tester);
  });

  testWidgets('session end action is visible on Start and session detail', (
    tester,
  ) async {
    final quick = await repository.startQuickSession();
    await tester.pumpWidget(_testApp(database, const TodayScreen()));
    await _pumpUi(tester);
    expect(find.text('Beëindigen'), findsOneWidget);
    await _disposeTestTree(tester);

    await tester.pumpWidget(
      _testApp(database, ActiveSessionScreen(sessionId: quick.sessionId)),
    );
    await _pumpUi(tester);
    expect(find.text('Beëindigen'), findsOneWidget);
    await _disposeTestTree(tester);
  });
}

StoredPhotoAlignment _alignment(
  String imageId, {
  int rotationQuarterTurns = 0,
  String planarityStatus = 'accepted',
}) => StoredPhotoAlignment(
  imageId: imageId,
  orderedCorners: const [
    NormalizedPoint(x: 0.1, y: 0.1),
    NormalizedPoint(x: 0.9, y: 0.1),
    NormalizedPoint(x: 0.9, y: 0.9),
    NormalizedPoint(x: 0.1, y: 0.9),
  ],
  homographyMatrix: const [687.5, 0, -343.75, 0, 687.5, -343.75, 0, 0, 1],
  algorithmVersion: geo.manualHomographyV2AlgorithmVersion,
  rotationQuarterTurns: rotationQuarterTurns,
  alignmentMode: 'fullCard',
  reprojectionRmsMm: 0,
  reprojectionMaxMm: 0,
  planarityStatus: planarityStatus,
  confirmedAtUtc: DateTime.now().toUtc(),
  updatedAtUtc: DateTime.now().toUtc(),
);

Future<QuickSessionResult> _createScoredSession(
  ShootingRepository repository,
) async {
  final quick = await repository.startQuickSession();
  await repository.saveSeriesDraft(
    seriesId: quick.draftSeriesId,
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: 5.6,
    impacts: const [ShotImpact(id: 'center', xMm: 0, yMm: 0)],
  );
  await repository.confirmSeries(quick.draftSeriesId);
  return quick;
}

Widget _testApp(AppDatabase database, Widget child) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(home: child),
);

Future<void> _pumpUi(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _disposeTestTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

extension on ImpactRecord {
  ShotImpact get asDomain => ShotImpact(
    id: id,
    xMm: xMm,
    yMm: yMm,
    sourceImageId: sourceImageId,
    imageXNormalized: imageXNormalized,
    imageYNormalized: imageYNormalized,
    multiplicity: multiplicity,
    isMiss: isMiss,
    isPositionUncertain: isPositionUncertain,
    targetBullId: targetBullId,
    rawScoreValue: rawScoreValue,
    scoreDisposition: ScoreDisposition.values.byName(scoreDisposition),
    placementMethod: ImpactPlacementMethod.values.byName(placementMethod),
    visionAnalysisId: visionAnalysisId,
    positionalUncertaintyMm: positionalUncertaintyMm,
  );
}
