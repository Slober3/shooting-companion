import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/more/build_information_screen.dart';
import 'package:shooting_companion/release/release_contract.dart';

void main() {
  test('bundled release contract contains integrated build facts', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final contract = await ReleaseContract.load();

    expect(contract.displayVersion, '0.8.0+1');
    expect(contract.data.databaseSchema, 8);
    expect(contract.data.backupManifest, 8);
    expect(contract.native.vision.abiVersion, 2);
    expect(contract.native.vision.engineVersion, 'vision-core-0.2.0');
    expect(
      contract.native.vision.candidateAlgorithmVersion,
      'dual-zone-evidence-v3',
    );
    expect(contract.native.vision.openCvVersion, '4.13.0');
    expect(contract.native.shotTimer.detectorVersion, 'impulse-v1');
    expect(
      contract.android.forbiddenPermissions,
      contains('android.permission.INTERNET'),
    );
  });

  test('build information accepts the verified bundled contract', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final contract = await ReleaseContract.load();
    final screen = BuildInformationScreen(contract: contract);

    expect(screen.contract, same(contract));
  });
}
