# CodeRainSaver

CodeRainSaver is a macOS screen saver project that recreates stylized green code rain with long readable trails, heavier VHS-like moire, and tuned stream timing.

## Release Builds

This repository ships two supported installer builds:

- `CodeRainSaver`: the main modern build for current macOS releases.
- `CodeRainIntel`: the Intel-compatible build for macOS Ventura 13.

Both are packaged as standalone `.pkg` installers in the release artifacts so they are easy to distinguish before download.

## Included In Public Releases

- `CodeRainSaver-1.1.0-macOS15-plus.pkg`
- `CodeRainIntel-1.1.0-Ventura-Intel.pkg`

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
xcodebuild -project CodeRainSaver.xcodeproj -scheme CodeRainIntel -configuration Release -destination 'generic/platform=macOS' build
```

To build the installer packages:

```sh
Scripts/build_release_installers.sh
```

## Notes

- The screen saver options sheet is unreliable on some newer macOS hosts.
- Releases are labeled by compatibility first so it is obvious which installer to use.
