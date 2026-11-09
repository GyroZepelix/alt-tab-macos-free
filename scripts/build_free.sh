#!/usr/bin/env bash
# Fork: build a Release AltTab with every Pro feature unlocked (PRO_BUILD) and update checks disabled.
# Output: DerivedData/Build/Products/Release/AltTab.app
#
# Signing: uses the "Local Self-Signed" certificate when it exists in your keychain (create it once with
# scripts/codesign/setup_local.sh). A stable certificate keeps the Accessibility / Screen Recording grants
# across rebuilds. Without it, the app is ad-hoc signed and macOS asks for both permissions again after
# every rebuild. Override with CODE_SIGN_IDENTITY=... ./scripts/build_free.sh

set -euo pipefail
cd "$(dirname "$0")/.."

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "error: full Xcode is required (Command Line Tools are not enough)." >&2
  echo "       Install Xcode, then: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

if [ -z "${CODE_SIGN_IDENTITY:-}" ]; then
  if security find-identity -v -p codesigning | grep -q '"Local Self-Signed"'; then
    CODE_SIGN_IDENTITY="Local Self-Signed"
  else
    echo "warning: no 'Local Self-Signed' certificate found, ad-hoc signing instead (see header comment)." >&2
    CODE_SIGN_IDENTITY="-"
  fi
fi

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')}"
[ -n "$VERSION" ] || VERSION="$(grep -m1 -oE '^#+ \[?[0-9]+\.[0-9]+\.[0-9]+' changelog.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
[ -n "$VERSION" ] || VERSION="0.0.0"

echo "Building AltTab $VERSION (PRO_BUILD), signing with: $CODE_SIGN_IDENTITY"

xcodebuild \
  -project alt-tab-macos.xcodeproj \
  -scheme Release \
  -configuration Release \
  -derivedDataPath DerivedData \
  CURRENT_PROJECT_VERSION="$VERSION" \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS="PRO_BUILD" \
  CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
  DEVELOPMENT_TEAM="" \
  OTHER_CODE_SIGN_FLAGS="--deep --options runtime" \
  build

APP="DerivedData/Build/Products/Release/AltTab.app"
codesign --verify --deep --strict --verbose=2 "$APP"
echo
echo "Built: $APP"
echo "Install: quit AltTab, then: rm -rf /Applications/AltTab.app && cp -R \"$APP\" /Applications/"
