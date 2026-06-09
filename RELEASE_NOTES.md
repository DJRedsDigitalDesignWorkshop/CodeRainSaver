# CodeRainSaver 1.1.14

This public release includes the two supported installer builds:

- `CodeRainAppleSilicon-1.1.14-Apple-Silicon.pkg`: native Apple Silicon build for current macOS releases.
- `CodeRainIntel-1.1.14-Ventura-Intel.pkg`: Intel-compatible build for macOS Ventura 13.

Both installers place the screen saver in `/Library/Screen Savers` so it appears in System Settings after install.

This update further reduces the System Settings preview load by sharply limiting column-strip redraws, preview depth, preview columns, and mutation churn.

The `CodeRainCatalina` target remains experimental and is not included in the public release assets.
