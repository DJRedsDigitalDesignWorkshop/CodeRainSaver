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
PKG_SIGNING_IDENTITY="${PKG_SIGNING_IDENTITY:-}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-}"
ALLOW_UNSIGNED_PACKAGES="${ALLOW_UNSIGNED_PACKAGES:-0}"

if [[ "$VERSION" == *'$('* || -z "$VERSION" ]]; then
  VERSION="1.1.1"
fi

XCODEGEN_BIN="${XCODEGEN_BIN:-}"
if [[ -n "$XCODEGEN_BIN" && ! -x "$XCODEGEN_BIN" ]]; then
  echo "error: XCODEGEN_BIN is set but not executable: $XCODEGEN_BIN" >&2
  exit 1
fi

if [[ -z "$XCODEGEN_BIN" ]] && command -v xcodegen >/dev/null 2>&1; then
  XCODEGEN_BIN="$(command -v xcodegen)"
fi

if [[ -n "$XCODEGEN_BIN" ]]; then
  "$XCODEGEN_BIN" generate --spec "$ROOT_DIR/project.yml"
fi

if [[ -z "$PKG_SIGNING_IDENTITY" && "$ALLOW_UNSIGNED_PACKAGES" != "1" ]]; then
  cat >&2 <<EOF
error: PKG_SIGNING_IDENTITY must be set to a valid Developer ID Installer identity.
Set ALLOW_UNSIGNED_PACKAGES=1 only for local smoke tests.
EOF
  exit 1
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
  local package_path="$DIST_ROOT/$package_name"
  local -a pkgbuild_args=(
    --root "$stage_dir"
    --identifier "$identifier"
    --version "$VERSION"
    --install-location "/"
  )

  rm -rf "$stage_dir"
  mkdir -p "$stage_dir/Library/Screen Savers"
  ditto "$RELEASE_ROOT/$bundle_name.saver" "$stage_dir/Library/Screen Savers/$bundle_name.saver"

  if [[ -n "$PKG_SIGNING_IDENTITY" ]]; then
    pkgbuild_args+=(--sign "$PKG_SIGNING_IDENTITY")
  else
    echo "warning: building unsigned local test package $package_name" >&2
  fi

  pkgbuild "${pkgbuild_args[@]}" "$package_path"
}

notarize_pkg() {
  local package_path="$1"
  xcrun notarytool submit "$package_path" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
  xcrun stapler staple "$package_path"
}

build_pkg "CodeRainSaver" "CodeRainSaver" "com.justinmarsh.coderainsaver.pkg" "CodeRainSaver-$VERSION-macOS15-plus.pkg"
build_pkg "CodeRainIntel" "CodeRainIntel" "com.justinmarsh.coderainintel.pkg" "CodeRainIntel-$VERSION-Ventura-Intel.pkg"

if [[ -n "$PKG_SIGNING_IDENTITY" && -n "$NOTARYTOOL_PROFILE" ]]; then
  notarize_pkg "$DIST_ROOT/CodeRainSaver-$VERSION-macOS15-plus.pkg"
  notarize_pkg "$DIST_ROOT/CodeRainIntel-$VERSION-Ventura-Intel.pkg"
elif [[ -n "$PKG_SIGNING_IDENTITY" ]]; then
  echo "note: packages were signed but not notarized; set NOTARYTOOL_PROFILE to notarize and staple them." >&2
fi

echo "Installers written to $DIST_ROOT"
