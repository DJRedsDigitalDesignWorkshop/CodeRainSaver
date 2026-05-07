# CodeRainSaver 1.1.4

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.4-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.4-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update keeps each column on a fixed centerline during glyph mutations, which removes the side-to-side wobble introduced by the optimized strip renderer.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
