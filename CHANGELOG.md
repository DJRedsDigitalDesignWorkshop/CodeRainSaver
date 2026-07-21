# Changelog

All notable changes to this project will be documented in this file.

## Unreleased
- No unreleased changes recorded yet.

## 1.1.19 - 2026-07-21
- Corrected cached rain-strip orientation so trails follow above downward-moving column heads.

## 1.1.18 - 2026-07-19
- Stopped suppressing visible desktop-layer legacy hosts so real screen saver playback cannot freeze after one frame on some M1 Macs.
- Hardened release signing checks so public builds require Developer ID Application, Developer ID Installer, and notarization credentials instead of accepting Apple Development signing.

## 1.1.17 - 2026-07-19
- Normalized full-screen glyph sizing against the native display pixel size so Retina display scaling does not make glyphs unexpectedly larger on similar M1 laptops.
- Kept preview sizing based on the preview panel dimensions so System Settings stays readable.
- Documented the Glyph Size slider as the manual size adjustment on top of the automatic display baseline.
- Added an optional `BUNDLE_SIGNING_IDENTITY` release-script setting for signing `.saver` bundles before packaging.

## 1.1.16 - 2026-06-08
- Stopped resetting `ScreenSaverView.animationTimeInterval` every frame.
- Avoided repeated ScreenSaver framework timer rebuilds and bundle metadata lookups while selected in System Settings.
- Kept the 1.1.15 cached preview renderer and visual tuning unchanged.

## 1.1.15 - 2026-06-08
- Made the System Settings preview reuse cached column strips instead of mutating glyphs continuously.
- Slowed preview-mode scrolling and reduced preview frame pacing to avoid pegging `legacyScreenSaver`.
- Kept full-screen playback visually richer while treating Settings as a lightweight preview host.

## 1.1.14 - 2026-06-08
- Reduced System Settings preview CPU by limiting preview column-strip redraws to one per frame.
- Lowered preview-only column count, trail depth, and motion load while preserving the full-screen visual style.
- Slowed glyph mutation churn so CodeRain does not continuously re-rasterize tall column strips while selected in Settings.

## 1.1.13 - 2026-05-09
- Added a per-frame column-strip render budget to prevent CPU spikes when many glyphs mutate at once.
- Slowed glyph mutation churn so dense scenes do not constantly re-rasterize tall column images.
- Capped the heaviest trail depth and full-screen column count to reduce Retina layer memory pressure.

## 1.1.12 - 2026-05-07
- Added CoreGraphics window-layer detection for desktop-backdrop Wallpaper hosts.
- Suppressed expensive rain rendering only for non-foreground backdrop hosts instead of relying on misleading AppKit window levels.

## 1.1.11 - 2026-05-07
- Removed the hard stop for inactive desktop-level hosts so real screen saver playback cannot freeze after one frame.
- Kept inactive wallpaper-style hosts throttled instead of fully rendering at foreground speed.

## 1.1.10 - 2026-05-07
- Stopped inactive desktop-level Wallpaper hosts from rendering the full rain loop.
- Kept real screen-saver-level windows animated, avoiding the one-frame freeze from the earlier active-app gate.
- Cached session lock-state checks instead of querying CoreGraphics every frame.

## 1.1.9 - 2026-05-07
- Kept visible screen saver hosts animated even when macOS does not report the host app as active.
- Changed inactive visible hosts from a hard pause to a reduced-rate render loop.

## 1.1.8 - 2026-05-07
- Stopped the background Wallpaper-flavored legacyScreenSaver host from rendering continuously.
- Preserved full rendering for preview/options, the active foreground saver host, and locked-session playback.

## 1.1.7 - 2026-05-07
- Restored animation in full-screen screen saver hosts by avoiding unreliable occlusion-state checks.
- Kept hidden/preloaded host throttling based on a visible attached window.

## 1.1.6 - 2026-05-07
- Paused high-frequency rendering when macOS preloads the selected idle screen saver in a hidden host.
- Reduced the hidden host timer to a one-second heartbeat until the saver window is visible again.

## 1.1.5 - 2026-05-07
- Drew glyphs into fixed-size cells so character changes cannot resize a column.
- Kept optimized column strip dimensions deterministic for each font size and visible depth.

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
