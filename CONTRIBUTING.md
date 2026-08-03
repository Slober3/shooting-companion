# Contributing

1. Open an issue describing the behavior and affected module.
2. Keep domain, scoring, storage, photo geometry and UI changes in their existing boundaries.
3. Add tests for every score rule, migration or geometry change.
4. Never commit private target photos, exports, backups, serial numbers or signing keys.
5. Run the local quality gate before opening a pull request:

```powershell
cd apps/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Use conventional commit subjects such as `feat:`, `fix:`, `test:` and `docs:`.
Target profile snapshots remain immutable. Confirmed scores change only through
an explicit user edit that replaces impacts and aggregates atomically.
