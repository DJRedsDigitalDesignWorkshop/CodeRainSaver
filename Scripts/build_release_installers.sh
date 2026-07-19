#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/CodeRainSaver.xcodeproj"
BUILD_ROOT="$ROOT_DIR/build"
RELEASE_ROOT="$BUILD_ROOT/Release"
STAGING_ROOT="$BUILD_ROOT/release-staging"
DIST_ROOT="$ROOT_DIR/dist"
DERIVED_DATA_ROOT="$BUILD_ROOT/DerivedData"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Info.plist" 2>/dev/null || true)"
BUNDLE_SIGNING_IDENTITY="${BUNDLE_SIGNING_IDENTITY:-}"
PKG_SIGNING_IDENTITY="${PKG_SIGNING_IDENTITY:-}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-}"
ALLOW_UNSIGNED_PACKAGES="${ALLOW_UNSIGNED_PACKAGES:-0}"
ALLOW_DEVELOPMENT_BUNDLE_SIGNING="${ALLOW_DEVELOPMENT_BUNDLE_SIGNING:-0}"

if [[ "$VERSION" == *'$('* || -z "$VERSION" ]]; then
  VERSION=""
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

if [[ -n "$BUNDLE_SIGNING_IDENTITY" && "$BUNDLE_SIGNING_IDENTITY" != Developer\ ID\ Application:* && "$ALLOW_DEVELOPMENT_BUNDLE_SIGNING" != "1" ]]; then
  cat >&2 <<EOF
error: BUNDLE_SIGNING_IDENTITY must be a Developer ID Application identity for release builds.
Set ALLOW_DEVELOPMENT_BUNDLE_SIGNING=1 only for local smoke tests with Apple Development certificates.
EOF
  exit 1
fi

if [[ -n "$PKG_SIGNING_IDENTITY" && "$PKG_SIGNING_IDENTITY" != Developer\ ID\ Installer:* ]]; then
  cat >&2 <<EOF
error: PKG_SIGNING_IDENTITY must be a Developer ID Installer identity.
Apple Development certificates cannot sign installer packages for public distribution.
EOF
  exit 1
fi

if [[ "$ALLOW_UNSIGNED_PACKAGES" != "1" && -z "$BUNDLE_SIGNING_IDENTITY" ]]; then
  cat >&2 <<EOF
error: BUNDLE_SIGNING_IDENTITY must be set to a valid Developer ID Application identity.
Set ALLOW_UNSIGNED_PACKAGES=1 only for local smoke tests.
EOF
  exit 1
fi

if [[ "$ALLOW_UNSIGNED_PACKAGES" != "1" && -z "$PKG_SIGNING_IDENTITY" ]]; then
  cat >&2 <<EOF
error: PKG_SIGNING_IDENTITY must be set to a valid Developer ID Installer identity.
Set ALLOW_UNSIGNED_PACKAGES=1 only for local smoke tests.
EOF
  exit 1
fi

if [[ "$ALLOW_UNSIGNED_PACKAGES" != "1" && -z "$NOTARYTOOL_PROFILE" ]]; then
  cat >&2 <<EOF
error: NOTARYTOOL_PROFILE must be set for public release builds so installers are notarized and stapled.
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
  -scheme CodeRainAppleSilicon \
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

sign_bundle() {
  local bundle_name="$1"
  local bundle_path="$RELEASE_ROOT/$bundle_name.saver"
  local -a codesign_args=(
    --force
    --sign "$BUNDLE_SIGNING_IDENTITY"
  )

  if [[ -z "$BUNDLE_SIGNING_IDENTITY" ]]; then
    echo "warning: leaving $bundle_name.saver ad-hoc signed for local smoke testing" >&2
    return
  fi

  if [[ "$BUNDLE_SIGNING_IDENTITY" == Developer\ ID\ Application:* ]]; then
    codesign_args+=(--options runtime --timestamp)
  else
    codesign_args+=(--timestamp=none)
  fi

  codesign "${codesign_args[@]}" "$bundle_path"
  codesign --verify --strict --verbose=2 "$bundle_path"
}

sign_bundle "CodeRainAppleSilicon"
sign_bundle "CodeRainIntel"

if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$RELEASE_ROOT/CodeRainAppleSilicon.saver/Contents/Info.plist" 2>/dev/null || true)"
fi

if [[ "$VERSION" == *'$('* || -z "$VERSION" ]]; then
  echo "error: unable to determine concrete bundle version for release packages." >&2
  exit 1
fi

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

build_pkg "CodeRainAppleSilicon" "CodeRainAppleSilicon" "com.justinmarsh.coderainapplesilicon.pkg" "CodeRainAppleSilicon-$VERSION-Apple-Silicon.pkg"
build_pkg "CodeRainIntel" "CodeRainIntel" "com.justinmarsh.coderainintel.pkg" "CodeRainIntel-$VERSION-Ventura-Intel.pkg"

if [[ -n "$PKG_SIGNING_IDENTITY" ]]; then
  pkgutil --check-signature "$DIST_ROOT/CodeRainAppleSilicon-$VERSION-Apple-Silicon.pkg"
  pkgutil --check-signature "$DIST_ROOT/CodeRainIntel-$VERSION-Ventura-Intel.pkg"
fi

if [[ -n "$PKG_SIGNING_IDENTITY" && -n "$NOTARYTOOL_PROFILE" ]]; then
  notarize_pkg "$DIST_ROOT/CodeRainAppleSilicon-$VERSION-Apple-Silicon.pkg"
  notarize_pkg "$DIST_ROOT/CodeRainIntel-$VERSION-Ventura-Intel.pkg"
elif [[ -n "$PKG_SIGNING_IDENTITY" ]]; then
  echo "note: packages were signed but not notarized; set NOTARYTOOL_PROFILE to notarize and staple them." >&2
fi

echo "Installers written to $DIST_ROOT"
