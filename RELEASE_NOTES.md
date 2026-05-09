# CodeRainSaver 1.1.13

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.13-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.13-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update suppresses desktop-backdrop Wallpaper hosts and adds renderer back-pressure so dense Matrix rain does not continuously re-rasterize hundreds of tall column strips.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
