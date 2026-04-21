#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/CodeRainSaver.xcodeproj"
BUILD_ROOT="$ROOT_DIR/build"
RELEASE_ROOT="$BUILD_ROOT/Build/Products/Release"
STAGING_ROOT="$BUILD_ROOT/release-staging"
DIST_ROOT="$ROOT_DIR/dist"
DERIVED_DATA_ROOT="$BUILD_ROOT/DerivedData"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Info.plist" 2>/dev/null || true)"

if [[ "$VERSION" == *'$('* || -z "$VERSION" ]]; then
  VERSION="1.1.0"
fi

XCODEGEN_BIN="${XCODEGEN_BIN:-}"
if [[ -z "$XCODEGEN_BIN" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    XCODEGEN_BIN="$(command -v xcodegen)"
  elif [[ -x "$HOME/Downloads/xcodegen/bin/xcodegen" ]]; then
    XCODEGEN_BIN="$HOME/Downloads/xcodegen/bin/xcodegen"
  fi
fi

if [[ -n "$XCODEGEN_BIN" ]]; then
  "$XCODEGEN_BIN" generate --spec "$ROOT_DIR/project.yml"
fi

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

rm -rf "$STAGING_ROOT"
mkdir -p "$DIST_ROOT"
mkdir -p "$DERIVED_DATA_ROOT"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme CodeRainSaver \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_ROOT" \
  SYMROOT="$BUILD_ROOT" \
  OBJROOT="$BUILD_ROOT/Intermediates.noindex" \
  build

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme CodeRainIntel \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_ROOT" \
  SYMROOT="$BUILD_ROOT" \
  OBJROOT="$BUILD_ROOT/Intermediates.noindex" \
  build

build_pkg() {
  local product_name="$1"
  local bundle_name="$2"
  local identifier="$3"
  local package_name="$4"
  local stage_dir="$STAGING_ROOT/$product_name"

  rm -rf "$stage_dir"
  mkdir -p "$stage_dir/Library/Screen Savers"
  ditto "$RELEASE_ROOT/$bundle_name.saver" "$stage_dir/Library/Screen Savers/$bundle_name.saver"

  pkgbuild \
    --root "$stage_dir" \
    --identifier "$identifier" \
    --version "$VERSION" \
    --install-location "/" \
    "$DIST_ROOT/$package_name"
}

build_pkg "CodeRainSaver" "CodeRainSaver" "com.justinmarsh.coderainsaver.pkg" "CodeRainSaver-$VERSION-macOS15-plus.pkg"
build_pkg "CodeRainIntel" "CodeRainIntel" "com.justinmarsh.coderainintel.pkg" "CodeRainIntel-$VERSION-Ventura-Intel.pkg"

echo "Installers written to $DIST_ROOT"
