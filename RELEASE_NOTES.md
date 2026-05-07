# CodeRainSaver 1.1.6

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.6-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.6-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update throttles hidden/preloaded screen saver hosts so macOS can keep CodeRain selected as the idle saver without continuously rendering while the saver is not visible.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
