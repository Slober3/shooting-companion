import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/features/more/more_screen.dart';

void main() {
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
}
