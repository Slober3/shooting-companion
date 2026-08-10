# Third-party notices

## Noto Sans

The Android app embeds `NotoSans-Regular.ttf` and `NotoSans-Bold.ttf` for local
Unicode PDF generation. Copyright 2018 The Noto Project Authors.

The font software is distributed under the SIL Open Font License, Version 1.1.
The complete license text is included at
`third_party/licenses/NotoSans-OFL.txt`.

Source: <https://github.com/notofonts/noto-fonts>

## OpenCV 4.13.0

The Android vision build statically links the official OpenCV 4.13.0 Android
SDK modules required for local image decoding and processing. OpenCV is
distributed under the Apache License, Version 2.0.

Source: <https://github.com/opencv/opencv/releases/tag/4.13.0>

Verified Android SDK archive SHA-256:
`edfda20fdf65d0bd45391d168ec5261dd30b600b00279c4d910d7f1c3e020f0f`.

The OpenCV license and the third-party notices shipped with the exact Android
SDK are included under `third_party/licenses/OpenCV-4.13.0/`. This includes the
notices for codec and runtime components that can be pulled into the statically
linked Android library.
