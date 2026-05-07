# Changelog

All notable changes to this project will be documented in this file.

## Unreleased
- No unreleased changes recorded yet.

## 1.1.4 - 2026-05-07
- Fixed visual column wobble by centering glyph sprites inside fixed-width column strips.
- Pixel-aligned animated strip origins without re-integralizing layer sizes every frame.

## 1.1.3 - 2026-05-06
- Added a native Apple Silicon-only `CodeRainAppleSilicon` screen saver target.
- Updated release packaging to produce separate Apple Silicon and Intel installers.

## 1.1.2 - 2026-05-06
- Reworked the modern renderer to cache each code-rain column as a single moving strip layer.
- Reduced Core Animation layer count substantially to lower CPU and memory use on high-density displays.

## 1.1.1 - 2026-04-21
- Sanitized and clamped shared preferences before using them in renderer math.
- Hardened the release packaging script to avoid untrusted `Downloads` tooling.
- Made public release packaging require a signing identity by default and added optional notarization support.

## 1.1.0 - 2026-04-21
- Prepared the project for a public GitHub release.
- Added shared project versioning for all build targets.
- Added a release packaging script that creates clearly labeled installers for `CodeRainSaver` and `CodeRainIntel`.
- Updated the README with release, install, and packaging guidance.
- Added an MIT license for public distribution.

## Workspace Baseline - 2026-04-11
- Added a project changelog.
- Captured this project in the workspace baseline so future diffs have a durable history.
