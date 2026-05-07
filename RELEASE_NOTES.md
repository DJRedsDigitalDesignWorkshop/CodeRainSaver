# CodeRainSaver 1.1.11

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.11-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.11-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update removes the hard wallpaper-host pause so real screen saver playback cannot freeze after one frame, while still throttling inactive wallpaper-style hosts.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
