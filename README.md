<img width="1920" height="1080" alt="Screenshot 2026-04-21 at 1 02 55 PM (2)" src="https://github.com/user-attachments/assets/85f27a90-b35b-4551-b544-698c3a8ed1c2" />
# CodeRainSaver

CodeRainSaver is a macOS screen saver project that recreates stylized green code rain with long readable trails, heavier VHS-like moire, and tuned stream timing.

This is THE BEST matrix code screen saver that works with macos tahoe.  Its also the only one.  Enjoy. 

## Release Builds

This repository ships two supported installer builds:

- `CodeRainAppleSilicon`: the native Apple Silicon build for current macOS releases.
- `CodeRainIntel`: the Intel-compatible build for macOS Ventura 13.

Both are packaged as standalone `.pkg` installers in the release artifacts so they are easy to distinguish before download.

## Included In Public Releases

- `CodeRainAppleSilicon-1.1.3-Apple-Silicon.pkg`
- `CodeRainIntel-1.1.3-Ventura-Intel.pkg`

The experimental `CodeRainCatalina` target stays in the source tree, but it is not part of the public release set.

## Install

1. Download the installer that matches your machine.
2. Open the `.pkg`.
3. The installer places the `.saver` bundle in `/Library/Screen Savers`.
4. Open System Settings and select the saver.

## Build From Source

If `xcodegen` is installed, regenerate the project first:

```sh
xcodegen generate
```

Then build the release bundles:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project CodeRainSaver.xcodeproj -scheme CodeRainSaver -configuration Release -destination 'generic/platform=macOS' build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project CodeRainSaver.xcodeproj -scheme CodeRainAppleSilicon -configuration Release -destination 'generic/platform=macOS' build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project CodeRainSaver.xcodeproj -scheme CodeRainIntel -configuration Release -destination 'generic/platform=macOS' build
```

To build signed installer packages:

```sh
PKG_SIGNING_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
Scripts/build_release_installers.sh
```

Optional notarization:

```sh
PKG_SIGNING_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
NOTARYTOOL_PROFILE="your-notarytool-profile" \
Scripts/build_release_installers.sh
```

For local packaging tests only, you can opt into unsigned packages:

```sh
ALLOW_UNSIGNED_PACKAGES=1 Scripts/build_release_installers.sh
```

## Notes

- The screen saver options sheet is unreliable on some newer macOS hosts.
- Releases are labeled by compatibility first so it is obvious which installer to use.
