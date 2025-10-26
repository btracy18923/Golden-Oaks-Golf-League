# Android APK Build Instructions

This repository is configured to automatically build an Android APK using GitHub Actions and Buildozer.

## Automatic Build (GitHub Actions)

1. Push your code to the main branch on GitHub
2. GitHub Actions will automatically trigger the build
3. The APK will be available as an artifact after the build completes
4. Download the APK from the Actions tab

## Manual Build (Local)

If you want to build locally:

1. Install buildozer: `pip install buildozer`
2. Run: `buildozer android debug`
3. The APK will be in the `bin/` directory

## Requirements

- Python 3.9+
- Kivy framework
- Android SDK (handled automatically by buildozer)
- Java 17 (for GitHub Actions)

## Notes

- The app is configured for landscape orientation
- Target Android API: 33
- Minimum Android API: 21
- Supported architectures: arm64-v8a, armeabi-v7a