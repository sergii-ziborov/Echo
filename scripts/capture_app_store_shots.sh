#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED=/tmp/EchoShotBuild
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Echo.app"
BUNDLE=com.sergiiziborov.Echo

IPHONE69=42F73E2F-CBDC-42B0-86D8-EED7CCE9B3AC
IPHONE65=F26A5919-420C-4779-892E-E9D548A039F2
IPAD13=47A57182-C38C-4D1F-A7F6-E6FCDFC6140A

cd "$ROOT"
xcodegen generate
xcodebuild -project Echo.xcodeproj -scheme Echo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  -configuration Debug \
  build

capture() {
  local udid="$1" dest="$2" width="$3" height="$4"
  shift 4
  mkdir -p "$dest"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$APP"
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true

  while (( $# >= 3 )); do
    local arg="$1" wait="$2" file="$3"
    shift 3
    xcrun simctl terminate "$udid" "$BUNDLE" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BUNDLE" "$arg" >/dev/null
    sleep "$wait"
    local raw="/tmp/echo-shot-raw.png"
    xcrun simctl io "$udid" screenshot "$raw"
    sips -z "$height" "$width" -s format jpeg -s formatOptions 88 "$raw" --out "$dest/$file" >/dev/null
    echo "wrote $dest/$file"
  done
}

mkdir -p "$ROOT/docs/app-store/iphone/play" "$ROOT/docs/app-store/iphone/menu" \
  "$ROOT/docs/app-store/iphone65/play" "$ROOT/docs/app-store/iphone65/menu" \
  "$ROOT/docs/app-store/ipad"

capture "$IPHONE69" "$ROOT/docs/app-store/iphone/play" 1320 2868 \
  -shot-play 3.4 01-gameplay.jpg \
  -shot-laser 3.4 02-lasers.jpg
capture "$IPHONE69" "$ROOT/docs/app-store/iphone/menu" 1320 2868 \
  -shot-worlds 1.8 03-atlas.jpg \
  -shot-research 1.8 04-research.jpg \
  -shot-shop 1.8 05-lab.jpg \
  -shot-wiki 1.8 06-wiki.jpg \
  -shot-home 1.8 07-home.jpg

capture "$IPHONE65" "$ROOT/docs/app-store/iphone65/play" 1284 2778 \
  -shot-play 3.4 01-gameplay.jpg \
  -shot-laser 3.4 02-lasers.jpg
capture "$IPHONE65" "$ROOT/docs/app-store/iphone65/menu" 1284 2778 \
  -shot-worlds 1.8 03-atlas.jpg \
  -shot-research 1.8 04-research.jpg \
  -shot-shop 1.8 05-lab.jpg \
  -shot-wiki 1.8 06-wiki.jpg \
  -shot-home 1.8 07-home.jpg

capture "$IPAD13" "$ROOT/docs/app-store/ipad" 2064 2752 \
  -shot-play 3.4 01-gameplay.jpg \
  -shot-worlds 1.8 02-atlas.jpg \
  -shot-research 1.8 03-research.jpg \
  -shot-shop 1.8 04-lab.jpg \
  -shot-home 1.8 05-home.jpg

# remove stale flat captures if they are still sitting in the parent folder
rm -f "$ROOT"/docs/app-store/iphone-*.jpg \
      "$ROOT"/docs/app-store/iphone65-*.jpg \
      "$ROOT"/docs/app-store/ipad-*.jpg

echo "screenshots ready"
