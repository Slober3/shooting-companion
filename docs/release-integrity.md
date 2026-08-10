# Release integrity contract

`apps/mobile/assets/release_contract.json` is the canonical, versioned release
contract. It is bundled into the app and shown under **Over en privacy >
Buildinformatie**. The same file drives CI; the UI therefore cannot silently
describe a different app, database or native engine than the release gate.

The contract fixes these coupled facts:

- Flutter version name and build number;
- Android application ID;
- Drift database schema, backup manifest and SCB1 container;
- required user-facing entry routes;
- required and forbidden Android permissions;
- release ABI and required packaged native libraries;
- vision ABI, engine version, OpenCV version and archive checksum;
- acoustic shot-timer detector version.

Run before every release:

```powershell
python tools/verify_release_contract.py
python tools/check_privacy_leaks.py
python -m unittest discover -s tools/tests -p "test_*.py"
```

After producing the APK, validate the actual package as well:

```powershell
python tools/verify_release_contract.py `
  --apk apps/mobile/build/app/outputs/flutter-apk/app-release.apk `
  --apkanalyzer "$env:ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer.bat"
```

The APK check reads its application ID, version and permissions using Android's
`apkanalyzer`, opens the APK as an archive, verifies the required arm64 vision
library and confirms that the compiled library exposes the contracted engine
version.

## Changing a release fact

Change the implementation and contract in one reviewable commit. Never weaken a
check merely to make CI green. In particular:

1. A database schema change needs its migration and fixture before increasing
   `databaseSchema`.
2. A backup payload change needs adapters and roundtrip tests before increasing
   `backupManifest`.
3. A permission addition needs an explicit privacy explanation and UI entry
   point before it enters `requiredPermissions`.
4. Native ABI or engine changes must update both native headers, FFI tests,
   documentation and the contract.
5. A release is invalid when its APK was built with an overridden
   `--build-name` or `--build-number` that differs from the contract.

The contract is not a substitute for migration, behavior or physical-device
testing. It prevents a known class of integration failures: building a green APK
from a branch whose versioned subsystems do not actually belong together.
