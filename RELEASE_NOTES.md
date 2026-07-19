# CodeRainSaver 1.1.18

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.18-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.18-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update prevents visible screen saver playback from freezing after one frame on some M1 Macs where macOS reports the full-screen saver host as a desktop-layer legacy host.

The release script now requires Developer ID Application, Developer ID Installer, and notarization credentials for proper public signing. Apple Development signing is allowed only when explicitly enabled for local smoke tests.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
