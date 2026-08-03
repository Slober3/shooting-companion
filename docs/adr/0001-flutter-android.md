# ADR 0001: Flutter, Android-first

Accepted. Use Flutter 3.44.8 with minimum Android SDK 33. It provides one future
mobile UI codebase while pure Dart domain, scoring and photo-geometry packages
remain reusable. There is no native image-processing layer. iOS is not built in
0.2, but platform-neutral packages may not import Android APIs.
