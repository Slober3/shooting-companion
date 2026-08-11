import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/features/training_tools/drill_screens.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  testWidgets('V2 library exposes planner and never shows checkbox progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guidedTrainingActivityOverviewsProvider.overrideWith(
            (_) => Stream.value(const []),
          ),
        ],
        child: const MaterialApp(home: DrillLibraryScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('open-deterministic-planner')),
      findsOneWidget,
    );
    expect(find.text('Reeks voltooid'), findsNothing);
    expect(
      find.byKey(
        ValueKey(
          'drill-${BuiltInTrainingContent.catalog.drills.first.versionedId}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('drill source URL is selectable, copyable and accessible', (
    tester,
  ) async {
    final drill = BuiltInTrainingContent.catalog.drills.firstWhere(
      (item) => item.references.isNotEmpty,
    );
    final reference = drill.references.first;
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(MaterialApp(home: DrillDetailScreen(drill: drill)));
    final copy = find.byKey(ValueKey('copy-drill-reference-${reference.id}'));
    await tester.scrollUntilVisible(
      copy,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    // The detail screen deliberately reserves space for its action dock. Move
    // the reference card fully above that dock before exercising the button.
    await tester.drag(
      find.byKey(const ValueKey('drill-detail-list')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    expect(find.text(reference.url), findsOneWidget);
    final semanticWrapper = find
        .ancestor(of: copy, matching: find.byType(Semantics))
        .first;
    expect(
      tester.widget<Semantics>(semanticWrapper).properties.label,
      'Link kopiëren voor ${reference.title}',
    );
    await tester.tap(copy);
    await tester.pump();

    expect(copiedText, reference.url);
    expect(find.text('Link gekopieerd'), findsOneWidget);
    semantics.dispose();
  });
}
