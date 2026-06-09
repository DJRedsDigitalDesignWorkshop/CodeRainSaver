# CodeRainSaver 1.1.16

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.16-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.16-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update keeps the 1.1.15 visual tuning but avoids resetting the ScreenSaver animation timer every frame, which prevents the host from continuously rebuilding timer state while selected in System Settings.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
