import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion/features/scoring/target_canvas.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  testWidgets('target canvas adds a manual impact', (tester) async {
    var impacts = <ShotImpact>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                onChanged: (value) => setState(() => impacts = value),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(200, 200));
    await tester.pump();

    expect(impacts, hasLength(1));
    expect(impacts.single.xMm, closeTo(0, 0.01));
    expect(impacts.single.yMm, closeTo(0, 0.01));
  });
}
