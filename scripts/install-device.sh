#!/bin/sh
set -euo pipefail
# Build and install onto a paired physical iPhone. The watch app is embedded
# in Echo.app, so the paired Apple Watch picks it up through the iPhone.
# Usage: scripts/install-device.sh [device-id]
# Without an id it uses the first available iPhone from `xcrun devicectl list devices`.
cd "$(dirname "$0")/.."
APP="DerivedDataDevice/Build/Products/Debug-iphoneos/Echo.app"
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  DEVICE="$(xcrun devicectl list devices 2>/dev/null \
    | grep -E 'iPhone.* available.*physical' \
    | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' \
    | head -1 || true)"
fi
[ -n "$DEVICE" ] || { echo "No available iPhone. Connect and unlock it, or pass a device id." >&2; exit 1; }

xcodebuild -project Echo.xcodeproj \
  -scheme Echo \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath DerivedDataDevice \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  build

xcrun devicectl device install app --timeout 180 --device "$DEVICE" "$APP"
xcrun devicectl device process launch --device "$DEVICE" com.sergiiziborov.Echo
