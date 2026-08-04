import 'dart:math' as math;

enum SightAdjustmentUnit { moa, milliradian }

enum HorizontalAdjustmentDirection {
  positiveClicksMoveImpactLeft,
  positiveClicksMoveImpactRight,
}

enum VerticalAdjustmentDirection {
  positiveClicksMoveImpactUp,
  positiveClicksMoveImpactDown,
}

enum HorizontalImpactMovement { none, left, right }

enum VerticalImpactMovement { none, up, down }

enum SightCorrectionState { requiresDirectionConfirmation, provisional, ready }

enum SightCorrectionWarning { fewerThanFivePositionedShots }

class SightProfile {
  factory SightProfile({
    required String id,
    required String firearmId,
    required String name,
    required SightAdjustmentUnit adjustmentUnit,
    required double clickValue,
    required HorizontalAdjustmentDirection horizontalDirection,
    required VerticalAdjustmentDirection verticalDirection,
    double? zeroDistanceMeters,
  }) {
    if (!clickValue.isFinite || clickValue <= 0) {
      throw ArgumentError.value(clickValue, 'clickValue');
    }
    if (zeroDistanceMeters != null &&
        (!zeroDistanceMeters.isFinite || zeroDistanceMeters <= 0)) {
      throw ArgumentError.value(zeroDistanceMeters, 'zeroDistanceMeters');
    }
    return SightProfile._(
      id: _requiredText(id, 'id'),
      firearmId: _requiredText(firearmId, 'firearmId'),
      name: _requiredText(name, 'name'),
      adjustmentUnit: adjustmentUnit,
      clickValue: clickValue,
      horizontalDirection: horizontalDirection,
      verticalDirection: verticalDirection,
      zeroDistanceMeters: zeroDistanceMeters,
    );
  }

  const SightProfile._({
    required this.id,
    required this.firearmId,
    required this.name,
    required this.adjustmentUnit,
    required this.clickValue,
    required this.horizontalDirection,
    required this.verticalDirection,
    this.zeroDistanceMeters,
  });

  final String id;
  final String firearmId;
  final String name;
  final SightAdjustmentUnit adjustmentUnit;
  final double clickValue;
  final HorizontalAdjustmentDirection horizontalDirection;
  final VerticalAdjustmentDirection verticalDirection;
  final double? zeroDistanceMeters;

  Map<String, Object?> toJson() => {
    'id': id,
    'firearmId': firearmId,
    'name': name,
    'adjustmentUnit': adjustmentUnit.name,
    'clickValue': clickValue,
    'horizontalDirection': horizontalDirection.name,
    'verticalDirection': verticalDirection.name,
    'zeroDistanceMeters': zeroDistanceMeters,
  };

  factory SightProfile.fromJson(Map<String, Object?> json) => SightProfile(
    id: json['id']! as String,
    firearmId: json['firearmId']! as String,
    name: json['name']! as String,
    adjustmentUnit: SightAdjustmentUnit.values.byName(
      json['adjustmentUnit']! as String,
    ),
    clickValue: (json['clickValue']! as num).toDouble(),
    horizontalDirection: HorizontalAdjustmentDirection.values.byName(
      json['horizontalDirection']! as String,
    ),
    verticalDirection: VerticalAdjustmentDirection.values.byName(
      json['verticalDirection']! as String,
    ),
    zeroDistanceMeters: (json['zeroDistanceMeters'] as num?)?.toDouble(),
  );
}

class SightAxisCorrection<T extends Enum> {
  const SightAxisCorrection({
    required this.requiredImpactMovement,
    required this.angularCorrection,
    required this.absoluteClicks,
    required this.signedClicks,
  });

  final T requiredImpactMovement;
  final double angularCorrection;
  final int absoluteClicks;

  /// Signed relative to the profile's configured positive-click direction.
  /// It remains null until the user confirms both direction settings.
  final int? signedClicks;
}

class SightCorrectionResult {
  SightCorrectionResult({
    required this.state,
    required this.unit,
    required this.horizontal,
    required this.vertical,
    required Iterable<SightCorrectionWarning> warnings,
  }) : warnings = List.unmodifiable(warnings);

  final SightCorrectionState state;
  final SightAdjustmentUnit unit;
  final SightAxisCorrection<HorizontalImpactMovement> horizontal;
  final SightAxisCorrection<VerticalImpactMovement> vertical;
  final List<SightCorrectionWarning> warnings;

  bool get directionsConfirmed =>
      state != SightCorrectionState.requiresDirectionConfirmation;

  bool get isProvisional =>
      warnings.contains(SightCorrectionWarning.fewerThanFivePositionedShots);
}

abstract final class SightCorrectionCalculator {
  /// Calculates a correction from a group centroid.
  ///
  /// Target coordinates use positive x to the right and positive y downward.
  /// Signed click values are withheld until [directionsConfirmed] is true.
  static SightCorrectionResult calculate({
    required SightProfile profile,
    required double centroidXMm,
    required double centroidYMm,
    required double distanceMeters,
    required int positionedShotCount,
    bool directionsConfirmed = false,
  }) {
    if (!centroidXMm.isFinite || !centroidYMm.isFinite) {
      throw ArgumentError('Het groepscentrum moet eindig zijn.');
    }
    if (!distanceMeters.isFinite || distanceMeters <= 0) {
      throw ArgumentError.value(distanceMeters, 'distanceMeters');
    }
    if (positionedShotCount <= 0) {
      throw ArgumentError.value(positionedShotCount, 'positionedShotCount');
    }

    final horizontalMovement = centroidXMm > 0
        ? HorizontalImpactMovement.left
        : centroidXMm < 0
        ? HorizontalImpactMovement.right
        : HorizontalImpactMovement.none;
    final verticalMovement = centroidYMm > 0
        ? VerticalImpactMovement.up
        : centroidYMm < 0
        ? VerticalImpactMovement.down
        : VerticalImpactMovement.none;
    final horizontalAngular = _angularCorrection(
      centroidXMm.abs(),
      distanceMeters,
      profile.adjustmentUnit,
    );
    final verticalAngular = _angularCorrection(
      centroidYMm.abs(),
      distanceMeters,
      profile.adjustmentUnit,
    );
    final horizontalClicks = (horizontalAngular / profile.clickValue).round();
    final verticalClicks = (verticalAngular / profile.clickValue).round();
    final warnings = [
      if (positionedShotCount < 5)
        SightCorrectionWarning.fewerThanFivePositionedShots,
    ];
    final state = !directionsConfirmed
        ? SightCorrectionState.requiresDirectionConfirmation
        : warnings.isNotEmpty
        ? SightCorrectionState.provisional
        : SightCorrectionState.ready;

    return SightCorrectionResult(
      state: state,
      unit: profile.adjustmentUnit,
      horizontal: SightAxisCorrection(
        requiredImpactMovement: horizontalMovement,
        angularCorrection: horizontalAngular,
        absoluteClicks: horizontalClicks,
        signedClicks: directionsConfirmed
            ? _signedHorizontalClicks(
                horizontalMovement,
                horizontalClicks,
                profile.horizontalDirection,
              )
            : null,
      ),
      vertical: SightAxisCorrection(
        requiredImpactMovement: verticalMovement,
        angularCorrection: verticalAngular,
        absoluteClicks: verticalClicks,
        signedClicks: directionsConfirmed
            ? _signedVerticalClicks(
                verticalMovement,
                verticalClicks,
                profile.verticalDirection,
              )
            : null,
      ),
      warnings: warnings,
    );
  }

  static double _angularCorrection(
    double offsetMm,
    double distanceMeters,
    SightAdjustmentUnit unit,
  ) {
    final radians = math.atan(offsetMm / (distanceMeters * 1000));
    return switch (unit) {
      SightAdjustmentUnit.moa => radians * 180 / math.pi * 60,
      SightAdjustmentUnit.milliradian => radians * 1000,
    };
  }

  static int _signedHorizontalClicks(
    HorizontalImpactMovement movement,
    int clicks,
    HorizontalAdjustmentDirection positiveDirection,
  ) {
    if (movement == HorizontalImpactMovement.none || clicks == 0) return 0;
    final positiveMovesLeft =
        positiveDirection ==
        HorizontalAdjustmentDirection.positiveClicksMoveImpactLeft;
    final needsLeft = movement == HorizontalImpactMovement.left;
    return positiveMovesLeft == needsLeft ? clicks : -clicks;
  }

  static int _signedVerticalClicks(
    VerticalImpactMovement movement,
    int clicks,
    VerticalAdjustmentDirection positiveDirection,
  ) {
    if (movement == VerticalImpactMovement.none || clicks == 0) return 0;
    final positiveMovesUp =
        positiveDirection ==
        VerticalAdjustmentDirection.positiveClicksMoveImpactUp;
    final needsUp = movement == VerticalImpactMovement.up;
    return positiveMovesUp == needsUp ? clicks : -clicks;
  }
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}
