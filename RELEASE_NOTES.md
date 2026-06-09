# CodeRainSaver 1.1.15

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.15-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.15-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update makes the System Settings preview cache-first: it slows preview movement, limits preview columns and depth, and stops continuous glyph re-rasterization while selected in Settings.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
