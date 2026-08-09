import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image/image.dart' as image_lib;
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/photo/photo.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  setUpAll(() => initializeDateFormatting('nl_BE'));

  testWidgets(
    'thumbnail shows source and caption and long press opens actions',
    (tester) async {
      final image = _image(caption: 'Opstelling met voorste steun');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => PhotoThumbnailTile(
                image: image,
                badgeLabel: 'Reeks 2',
                onTap: () {},
                onLongPress: () =>
                    showPhotoActionsSheet(context: context, image: image),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reeks 2'), findsOneWidget);
      expect(find.text('Opstelling met voorste steun'), findsOneWidget);

      await tester.longPress(find.byType(PhotoThumbnailTile));
      await tester.pumpAndSettle();

      expect(find.text('Fotoacties'), findsOneWidget);
      expect(find.text('Beschrijving wijzigen'), findsOneWidget);
      expect(find.text('Foto verwijderen'), findsOneWidget);
    },
  );

  testWidgets('long thumbnail caption stays bounded at 200 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final image = _image(
      caption:
          'Een erg lange beschrijving van de opstelling die veilig over '
          'twee regels moet worden afgekapt.',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SizedBox(
              height: 174,
              child: PhotoThumbnailTile(
                image: image,
                badgeLabel: 'Scorefoto',
                onTap: () {},
                onLongPress: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final caption = tester.widget<Text>(find.text(image.caption!));
    expect(caption.maxLines, 2);
    expect(caption.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live viewer refreshes a changed and cleared caption',
    (tester) async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'shooting-photo-viewer-test-',
      );
      final photoFile = File('${tempDirectory.path}/photo.jpg')
        ..writeAsBytesSync(
          image_lib.encodeJpg(image_lib.Image(width: 8, height: 8)),
          flush: true,
        );
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await database.close();
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final repository = ShootingRepository(database);
      await _stage('seed defaults', repository.seedDefaults());
      final quick = await _stage(
        'quick session',
        repository.startQuickSession(),
      );
      final imageId = await _stage(
        'attach image',
        repository.attachImage(
          NewImageAsset(
            id: 'live-image',
            sessionId: quick.sessionId,
            role: ImageRole.attachment,
            path: photoFile.path,
            sha256: 'hash',
            width: 100,
            height: 100,
            sizeBytes: 1,
            caption: 'Eerste beschrijving',
          ),
        ),
      );
      Future<ImageAssetRecord> currentImage() => (database.select(
        database.imageAssets,
      )..where((row) => row.id.equals(imageId))).getSingle();
      final imageStream = StreamController<ImageAssetRecord?>();
      addTearDown(imageStream.close);
      imageStream.add(await currentImage());

      await _stage(
        'pump viewer',
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageProvider(imageId).overrideWith((_) => imageStream.stream),
            ],
            child: MaterialApp(
              home: PhotoViewerScreen(
                imageId: imageId,
                sourceLabel: 'Sessiefoto',
              ),
            ),
          ),
        ),
      );
      await _stage('initial stream pumps', _pumpStreams(tester));
      expect(find.text('Eerste beschrijving'), findsOneWidget);
      expect(find.textContaining('Sessiefoto'), findsOneWidget);

      final sessionBefore = (await _stage(
        'session before',
        repository.getSessionDetail(quick.sessionId),
      ))!.session;
      await tester.pump(const Duration(milliseconds: 2));
      await _stage(
        'update caption',
        repository.updateImageCaption(imageId, 'Nieuwe beschrijving'),
      );
      imageStream.add(await currentImage());
      await _stage('changed stream pumps', _pumpStreams(tester));
      expect(find.text('Eerste beschrijving'), findsNothing);
      expect(find.text('Nieuwe beschrijving'), findsOneWidget);
      final sessionAfter = (await _stage(
        'session after',
        repository.getSessionDetail(quick.sessionId),
      ))!.session;
      expect(
        sessionAfter.updatedAtUtc.isBefore(sessionBefore.updatedAtUtc),
        isFalse,
      );

      await _stage(
        'clear caption',
        repository.updateImageCaption(imageId, '   '),
      );
      imageStream.add(await currentImage());
      await _stage('cleared stream pumps', _pumpStreams(tester));
      expect(find.byKey(const ValueKey('photo-caption')), findsNothing);
      final storedImage = await currentImage();
      expect(storedImage.caption, isNull);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets('primary delete confirmation explains that impacts remain', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final quick = await repository.startQuickSession();
    final imageId = await repository.attachImage(
      NewImageAsset(
        id: 'primary-image',
        sessionId: quick.sessionId,
        seriesId: quick.draftSeriesId,
        role: ImageRole.primaryScoringPhoto,
        path: 'missing-primary-image.jpg',
        sha256: 'hash',
        width: 100,
        height: 100,
        sizeBytes: 1,
        caption: 'Kaart na reeks',
      ),
    );
    final image = await (database.select(
      database.imageAssets,
    )..where((row) => row.id.equals(imageId))).getSingle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton(
                onPressed: () => deletePhotoWithConfirmation(
                  context: context,
                  ref: ref,
                  image: image,
                  sourceLabel: 'Scorefoto',
                ),
                child: const Text('Verwijder'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Verwijder'));
    await tester.pumpAndSettle();
    expect(find.text('Kaart na reeks'), findsOneWidget);
    expect(
      find.textContaining('treffers en score blijven bewaard'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuleren'));
    await tester.pumpAndSettle();
    expect(
      await (database.select(
        database.imageAssets,
      )..where((row) => row.id.equals(imageId))).getSingleOrNull(),
      isNotNull,
    );
  });

  test(
    'deleting a primary photo clears alignment and source but preserves score',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = ShootingRepository(database);
      await repository.seedDefaults();
      final quick = await repository.startQuickSession();
      final imageId = await repository.attachImage(
        NewImageAsset(
          id: 'deleted-primary-image',
          sessionId: quick.sessionId,
          seriesId: quick.draftSeriesId,
          role: ImageRole.primaryScoringPhoto,
          path: 'already-missing-primary-image.jpg',
          sha256: 'hash',
          width: 100,
          height: 100,
          sizeBytes: 1,
          caption: 'Kaart die verwijderd wordt',
        ),
      );
      await repository.savePhotoAlignment(
        StoredPhotoAlignment(
          imageId: imageId,
          orderedCorners: const [
            NormalizedPoint(x: 0.1, y: 0.1),
            NormalizedPoint(x: 0.9, y: 0.1),
            NormalizedPoint(x: 0.9, y: 0.9),
            NormalizedPoint(x: 0.1, y: 0.9),
          ],
          homographyMatrix: const [
            687.5,
            0,
            -343.75,
            0,
            687.5,
            -343.75,
            0,
            0,
            1,
          ],
          algorithmVersion: 'manual-homography-v1',
          updatedAtUtc: DateTime.utc(2026, 8, 5),
        ),
      );
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: [
          ShotImpact(
            id: 'photo-impact',
            xMm: 0,
            yMm: 0,
            sourceImageId: imageId,
            imageXNormalized: 0.5,
            imageYNormalized: 0.5,
          ),
        ],
      );

      final before = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(before!.primaryImage?.id, imageId);
      expect(before.photoAlignment, isNotNull);

      await repository.deleteImage(imageId);
      await repository.deleteImage(imageId);

      final after = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(after!.primaryImage, isNull);
      expect(after.photoAlignment, isNull);
      expect(after.impacts.single.sourceImageId, isNull);
      expect(after.impacts.single.scoreValue, before.impacts.single.scoreValue);
      expect(after.series.totalScore, before.series.totalScore);
    },
  );
}

ImageAssetRecord _image({String? caption}) => ImageAssetRecord(
  id: 'image',
  sessionId: 'session',
  role: ImageRole.attachment.name,
  path: 'missing-image.jpg',
  sha256: 'hash',
  width: 100,
  height: 100,
  sizeBytes: 1,
  caption: caption,
  createdAtUtc: DateTime.utc(2026, 8, 4, 12),
  updatedAtUtc: DateTime.utc(2026, 8, 4, 12),
);

Future<void> _pumpStreams(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<T> _stage<T>(String _, Future<T> operation) => operation;
