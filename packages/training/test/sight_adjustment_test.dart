import 'dart:math' as math;

import 'package:shooting_companion_training/training.dart';
import 'package:test/test.dart';

void main() {
  group('SightProfile', () {
    test('roundtrips all direction and unit metadata', () {
      final source = _profile(zeroDistanceMeters: 25);
      final restored = SightProfile.fromJson(source.toJson());

      expect(restored.toJson(), source.toJson());
      expect(restored.zeroDistanceMeters, 25);
    });

    test('rejects unusable click and distance values', () {
      expect(() => _profile(clickValue: 0), throwsArgumentError);
      expect(() => _profile(zeroDistanceMeters: -1), throwsArgumentError);
    });
  });

  group('SightCorrectionCalculator', () {
    test('withholds signed clicks until directions are confirmed', () {
      final offsetForOneMoaAt100m = math.tan(math.pi / 180 / 60) * 100 * 1000;
      final result = SightCorrectionCalculator.calculate(
        profile: _profile(),
        centroidXMm: offsetForOneMoaAt100m,
        centroidYMm: offsetForOneMoaAt100m,
        distanceMeters: 100,
        positionedShotCount: 5,
      );

      expect(result.state, SightCorrectionState.requiresDirectionConfirmation);
      expect(
        result.horizontal.requiredImpactMovement,
        HorizontalImpactMovement.left,
      );
      expect(result.vertical.requiredImpactMovement, VerticalImpactMovement.up);
      expect(result.horizontal.angularCorrection, closeTo(1, 1e-10));
      expect(result.horizontal.absoluteClicks, 4);
      expect(result.vertical.absoluteClicks, 4);
      expect(result.horizontal.signedClicks, isNull);
      expect(result.vertical.signedClicks, isNull);
    });

    test('returns ready signed clicks after direction confirmation', () {
      final offset = math.tan(math.pi / 180 / 60) * 100 * 1000;
      final result = SightCorrectionCalculator.calculate(
        profile: _profile(),
        centroidXMm: offset,
        centroidYMm: offset,
        distanceMeters: 100,
        positionedShotCount: 5,
        directionsConfirmed: true,
      );

      expect(result.state, SightCorrectionState.ready);
      expect(result.horizontal.signedClicks, 4);
      expect(result.vertical.signedClicks, 4);
      expect(result.warnings, isEmpty);
    });

    test('respects profiles whose positive clicks move the opposite way', () {
      final profile = SightProfile(
        id: 'opposite',
        firearmId: 'firearm',
        name: 'Opposite',
        adjustmentUnit: SightAdjustmentUnit.moa,
        clickValue: 0.25,
        horizontalDirection:
            HorizontalAdjustmentDirection.positiveClicksMoveImpactRight,
        verticalDirection:
            VerticalAdjustmentDirection.positiveClicksMoveImpactDown,
      );
      final offset = math.tan(math.pi / 180 / 60) * 100 * 1000;
      final result = SightCorrectionCalculator.calculate(
        profile: profile,
        centroidXMm: offset,
        centroidYMm: offset,
        distanceMeters: 100,
        positionedShotCount: 5,
        directionsConfirmed: true,
      );

      expect(result.horizontal.signedClicks, -4);
      expect(result.vertical.signedClicks, -4);
    });

    test('qualifies recommendations made from fewer than five shots', () {
      final result = SightCorrectionCalculator.calculate(
        profile: _profile(),
        centroidXMm: -10,
        centroidYMm: 0,
        distanceMeters: 25,
        positionedShotCount: 4,
        directionsConfirmed: true,
      );

      expect(result.state, SightCorrectionState.provisional);
      expect(result.isProvisional, isTrue);
      expect(result.warnings, [
        SightCorrectionWarning.fewerThanFivePositionedShots,
      ]);
      expect(
        result.horizontal.requiredImpactMovement,
        HorizontalImpactMovement.right,
      );
    });

    test('calculates milliradian clicks and zero axes deterministically', () {
      final profile = SightProfile(
        id: 'mrad',
        firearmId: 'firearm',
        name: '0.1 mrad',
        adjustmentUnit: SightAdjustmentUnit.milliradian,
        clickValue: 0.1,
        horizontalDirection:
            HorizontalAdjustmentDirection.positiveClicksMoveImpactLeft,
        verticalDirection:
            VerticalAdjustmentDirection.positiveClicksMoveImpactUp,
      );
      final result = SightCorrectionCalculator.calculate(
        profile: profile,
        centroidXMm: 10,
        centroidYMm: 0,
        distanceMeters: 10,
        positionedShotCount: 10,
        directionsConfirmed: true,
      );

      expect(result.horizontal.angularCorrection, closeTo(1, 0.000001));
      expect(result.horizontal.absoluteClicks, 10);
      expect(
        result.vertical.requiredImpactMovement,
        VerticalImpactMovement.none,
      );
      expect(result.vertical.absoluteClicks, 0);
      expect(result.vertical.signedClicks, 0);
    });

    test('rejects missing or physically invalid measurement inputs', () {
      expect(
        () => SightCorrectionCalculator.calculate(
          profile: _profile(),
          centroidXMm: 0,
          centroidYMm: 0,
          distanceMeters: 0,
          positionedShotCount: 5,
        ),
        throwsArgumentError,
      );
      expect(
        () => SightCorrectionCalculator.calculate(
          profile: _profile(),
          centroidXMm: 0,
          centroidYMm: 0,
          distanceMeters: 25,
          positionedShotCount: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}

SightProfile _profile({double clickValue = 0.25, double? zeroDistanceMeters}) =>
    SightProfile(
      id: 'sight',
      firearmId: 'firearm',
      name: 'Testvizier',
      adjustmentUnit: SightAdjustmentUnit.moa,
      clickValue: clickValue,
      horizontalDirection:
          HorizontalAdjustmentDirection.positiveClicksMoveImpactLeft,
      verticalDirection: VerticalAdjustmentDirection.positiveClicksMoveImpactUp,
      zeroDistanceMeters: zeroDistanceMeters,
    );
