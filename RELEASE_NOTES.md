# CodeRainSaver 1.1.5

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.5-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.5-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update draws every glyph into a fixed-size cell and keeps every column strip at a deterministic size, which removes side-to-side drift and size pulsing during glyph mutations.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
