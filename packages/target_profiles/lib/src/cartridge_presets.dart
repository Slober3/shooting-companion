import 'package:shooting_companion_domain/domain.dart';

abstract final class CartridgePresets {
  static const twentyTwoLr = CartridgeProfile(
    id: 'cartridge-22-lr',
    name: '.22 LR',
    projectileDiameterMm: 5.60,
    notes: 'Nominale scorediameter; per munitieprofiel aanpasbaar.',
  );

  static const nineMm = CartridgeProfile(
    id: 'cartridge-9x19',
    name: '9×19 mm',
    projectileDiameterMm: 9.01,
    notes: 'Nominale scorediameter; per projectiel aanpasbaar.',
  );

  static const thirtyEightSpecial = CartridgeProfile(
    id: 'cartridge-38-special',
    name: '.38 Special',
    projectileDiameterMm: 9.07,
    notes: 'Afzonderlijk patroonprofiel; diameter is aanpasbaar.',
  );

  static const threeFiftySevenMagnum = CartridgeProfile(
    id: 'cartridge-357-magnum',
    name: '.357 Magnum',
    projectileDiameterMm: 9.07,
    notes: 'Afzonderlijk patroonprofiel; diameter is aanpasbaar.',
  );

  static const all = [
    twentyTwoLr,
    nineMm,
    thirtyEightSpecial,
    threeFiftySevenMagnum,
  ];
}
