# CodeRainSaver 1.1.9

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.9-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.9-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update keeps visible saver hosts animated even when Tahoe does not report them as active, while still slowing hidden/background hosts.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
