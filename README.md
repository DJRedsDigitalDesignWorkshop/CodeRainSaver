# CodeRainSaver

CodeRainSaver is a macOS `.saver` bundle that recreates the classic cascading neon code-rain feel with a custom `ScreenSaverView`.

## Controls

Open the screen saver options sheet in System Settings to adjust:

- Speed
- Darkness
- Moire
- Persistence
- Density
- Glow
- Glyph Size

## Build

1. Generate the Xcode project:

   ```sh
   "/Users/justinmarsh/Downloads/xcodegen/bin/xcodegen" generate
   ```

2. Build the bundle:

   ```sh
   xcodebuild -project CodeRainSaver.xcodeproj -scheme CodeRainSaver -configuration Release -destination 'generic/platform=macOS' build
   ```

## Install

Copy the built bundle into your user Screen Savers folder:

```sh
mkdir -p "$HOME/Library/Screen Savers"
cp -R build/Build/Products/Release/CodeRainSaver.saver "$HOME/Library/Screen Savers/"
```

Then open System Settings > Screen Saver and select `CodeRainSaver`.
