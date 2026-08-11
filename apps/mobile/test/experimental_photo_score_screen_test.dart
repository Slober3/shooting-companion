import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/vision_scan_repository.dart';
import 'package:shooting_companion/features/more/more_screen.dart';
import 'package:shooting_companion/features/vision/experimental_photo_score_screen.dart';
import 'package:shooting_companion/services/image_storage_service.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';

void main() {
  test('vision concept survives closing and reopening the database', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'shooting-companion-vision-resume-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final databaseFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}vision-resume.sqlite',
    );
    final firstDatabase = AppDatabase.forTesting(NativeDatabase(databaseFile));
    final firstRepository = VisionScanRepository(firstDatabase);
    final scanId = await firstRepository.createDraft(
      image: const StoredImage(
        path: 'internal/vision/concept.jpg',
        sha256: 'persistent-concept-sha256',
        width: 2400,
        height: 2400,
        sizeBytes: 123456,
      ),
    );
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase.forTesting(
      NativeDatabase(databaseFile),
    );
    addTearDown(reopenedDatabase.close);
    final reopened = await VisionScanRepository(
      reopenedDatabase,
    ).getDraft(scanId);

    expect(reopened, isNotNull);
    expect(reopened?.status, VisionScanDraftStatus.analysisNeeded.name);
    expect(reopened?.originalImagePath, 'internal/vision/concept.jpg');
    expect(reopened?.sha256, 'persistent-concept-sha256');
  });

  testWidgets('Meer exposes experimental photo scoring with draft count', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visionScanDraftCountProvider.overrideWith((ref) => Stream.value(2)),
        ],
        child: const MaterialApp(home: MoreScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Experimentele fotoscore'), findsOneWidget);
    expect(find.text('2 concepten'), findsOneWidget);
    expect(find.textContaining('ISSF-kaartfoto'), findsOneWidget);
  });

  testWidgets(
    'existing concept survives unsupported analysis and resumes in manual fallback',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = VisionScanRepository(database);
      final analyzer = _UnavailableVisionAnalyzer();
      addTearDown(database.close);

      final imageFile = File(
        '${Directory.current.path}${Platform.pathSeparator}test'
        '${Platform.pathSeparator}goldens${Platform.pathSeparator}'
        'training_diagrams${Platform.pathSeparator}'
        'target-evidence-layers.png',
      );
      expect(imageFile.existsSync(), isTrue);
      final scanId = await repository.createDraft(
        image: StoredImage(
          path: imageFile.path,
          sha256: 'synthetic-fixture-sha256',
          width: 412,
          height: 1000,
          sizeBytes: imageFile.lengthSync(),
        ),
      );
      final original = (await repository.getDraft(scanId))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            visionScanRepositoryProvider.overrideWithValue(repository),
            visionAnalyzerProvider.overrideWithValue(analyzer),
          ],
          child: const MaterialApp(home: MoreScreen()),
        ),
      );
      await _pumpUi(tester);

      expect(find.text('Experimentele fotoscore'), findsOneWidget);
      expect(find.text('1 concept'), findsOneWidget);

      await tester.tap(find.text('Experimentele fotoscore'));
      await _pumpUi(tester);

      expect(find.text('Experimentele fotoscore'), findsOneWidget);
      expect(find.text('Experimenteel'), findsOneWidget);
      expect(
        find.text('Automatische detector niet beschikbaar in deze build'),
        findsOneWidget,
      );
      expect(find.text('OpenCV-detector niet geladen.'), findsOneWidget);

      await _scrollUntilVisible(tester, find.text('Analyse nodig'));
      expect(find.text('Analyse nodig'), findsOneWidget);
      expect(find.text('Nog geen kandidaten'), findsOneWidget);

      await tester.tap(find.text('Analyse nodig'));
      await _pumpUi(tester);

      expect(find.text('Fotoscore'), findsOneWidget);
      expect(find.text('Handmatig uitlijnen'), findsOneWidget);
      expect(find.text('Analyseren'), findsOneWidget);

      await tester.tap(find.text('Analyseren'));
      await _pumpUi(tester);
      expect(analyzer.analyzeCalls, 0);

      final failed = (await repository.getDraft(scanId))!;
      expect(failed.id, original.id);
      expect(failed.originalImagePath, original.originalImagePath);
      expect(failed.sha256, original.sha256);
      expect(failed.targetProfileJson, original.targetProfileJson);
      expect(failed.projectileDiameterMm, original.projectileDiameterMm);
      expect(failed.createdAtUtc, original.createdAtUtc);
      expect(failed.candidatesJson, original.candidatesJson);
      expect(failed.reviewJson, original.reviewJson);
      expect(failed.status, VisionScanDraftStatus.failed.name);
      expect(failed.failureCode, contains('OpenCV-kandidaatdetector'));

      await _disposeWidgetTree(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            visionScanRepositoryProvider.overrideWithValue(repository),
            visionAnalyzerProvider.overrideWithValue(analyzer),
          ],
          child: const MaterialApp(home: MoreScreen()),
        ),
      );
      await _pumpUi(tester);
      expect(find.text('1 concept'), findsOneWidget);
      await tester.tap(find.text('Experimentele fotoscore'));
      await _scrollUntilVisible(tester, find.text('Opnieuw proberen'));

      expect(find.text('Opnieuw proberen'), findsOneWidget);
      expect(find.text('Nog geen kandidaten'), findsOneWidget);
      await tester.tap(find.text('Opnieuw proberen'));
      await _scrollUntilVisible(tester, find.text('Analyse niet voltooid'));

      expect(find.text('Fotoscore'), findsOneWidget);
      expect(find.text('Analyse niet voltooid'), findsOneWidget);
      expect(find.text('Handmatig uitlijnen'), findsOneWidget);
      expect(find.text('Opnieuw analyseren'), findsOneWidget);
      expect((await repository.getDraft(scanId))?.id, scanId);
      expect(tester.takeException(), isNull);

      await _disposeWidgetTree(tester);
    },
  );

  testWidgets(
    'leaving during capability check cancels without changing the concept',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = VisionScanRepository(database);
      final analyzer = _DelayedVisionAnalyzer();
      addTearDown(database.close);

      final imageFile = File(
        '${Directory.current.path}${Platform.pathSeparator}test'
        '${Platform.pathSeparator}goldens${Platform.pathSeparator}'
        'training_diagrams${Platform.pathSeparator}'
        'target-evidence-layers.png',
      );
      final scanId = await repository.createDraft(
        image: StoredImage(
          path: imageFile.path,
          sha256: 'delayed-capability-fixture',
          width: 412,
          height: 1000,
          sizeBytes: imageFile.lengthSync(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            visionScanRepositoryProvider.overrideWithValue(repository),
            visionAnalyzerProvider.overrideWithValue(analyzer),
          ],
          child: MaterialApp(home: VisionScanFlowScreen(scanId: scanId)),
        ),
      );
      await _pumpUi(tester);

      await tester.tap(find.text('Analyseren'));
      await _pumpUi(tester);
      expect(analyzer.capabilityCalls, 1);

      await _disposeWidgetTree(tester);
      expect(analyzer.cancelCalls, 1);
      analyzer.completeCapabilities();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));

      final draft = (await repository.getDraft(scanId))!;
      expect(draft.status, VisionScanDraftStatus.analysisNeeded.name);
      expect(draft.failureCode, isNull);
      expect(analyzer.analyzeCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

class _UnavailableVisionAnalyzer implements VisionAnalyzer {
  int analyzeCalls = 0;

  @override
  Future<VisionAnalyzerCapabilities> capabilities() async =>
      const VisionAnalyzerCapabilities.unavailable(
        'OpenCV-detector niet geladen.',
      );

  @override
  Future<AnalyzeTargetResult> analyze(AnalyzeTargetRequest request) async {
    analyzeCalls++;
    throw StateError(
      'De analyzer mag zonder kandidaatcapaciteit niet starten.',
    );
  }

  @override
  Future<void> cancel(String jobId) async {}
}

class _DelayedVisionAnalyzer implements VisionAnalyzer {
  final Completer<VisionAnalyzerCapabilities> _capabilities = Completer();
  int capabilityCalls = 0;
  int analyzeCalls = 0;
  int cancelCalls = 0;

  void completeCapabilities() {
    _capabilities.complete(
      const VisionAnalyzerCapabilities(
        available: true,
        abiVersion: 2,
        engineVersion: 'test',
        hasOpenCv: true,
        supportsRegistration: true,
        supportsCandidates: true,
      ),
    );
  }

  @override
  Future<VisionAnalyzerCapabilities> capabilities() {
    capabilityCalls++;
    return _capabilities.future;
  }

  @override
  Future<AnalyzeTargetResult> analyze(AnalyzeTargetRequest request) async {
    analyzeCalls++;
    throw StateError('Analyse mag na schermsluiting niet starten.');
  }

  @override
  Future<void> cancel(String jobId) async {
    cancelCalls++;
  }
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 12,
}) async {
  await _pumpUi(tester);
  for (var index = 0; index < attempts; index++) {
    if (finder.evaluate().isNotEmpty) return;
    final list = find.byType(ListView);
    if (list.evaluate().isEmpty) break;
    await tester.drag(list.last, const Offset(0, -240));
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Widget werd niet geladen: $finder');
}

Future<void> _disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}
