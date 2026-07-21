# CodeRainSaver 1.1.19

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.19-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.19-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update corrects the optimized rain-strip orientation so each bright head leads downward with its fading trail above it. It retains the visible-host animation fix for M1 Macs.

The release script now requires Developer ID Application, Developer ID Installer, and notarization credentials for proper public signing. Apple Development signing is allowed only when explicitly enabled for local smoke tests.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
