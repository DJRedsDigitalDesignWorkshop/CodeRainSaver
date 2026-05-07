# CodeRainSaver 1.1.8

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.8-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.8-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update prevents the background Wallpaper-flavored legacyScreenSaver host from rendering continuously while preserving real screen saver playback, preview, and options behavior.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
