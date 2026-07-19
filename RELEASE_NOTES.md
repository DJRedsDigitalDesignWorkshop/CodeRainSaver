# CodeRainSaver 1.1.17

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.17-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.17-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update normalizes full-screen glyph sizing against each display's native pixel size, so Retina display scaling should not make glyphs unexpectedly larger on similar M1 laptops. The Glyph Size slider remains available in the options sheet and companion controls app for manual tuning.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
