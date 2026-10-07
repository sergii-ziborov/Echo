#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${ECHO_SHOT_DERIVED:-/tmp/EchoShotBuild}"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Echo.app"
BUNDLE=com.sergiiziborov.Echo

simulator_id() {
  xcrun simctl list -j devices available | python3 -c '
import json, sys
name = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for device in devices:
        if device["name"] == name:
            print(device["udid"])
            sys.exit(0)
sys.exit("Missing simulator: " + name)
' "$1"
}

IPHONE69="${IPHONE69:-$(simulator_id 'Echo Shots 6.9')}"
IPHONE65="${IPHONE65:-$(simulator_id 'Echo Shots 6.5')}"
IPAD13="${IPAD13:-$(simulator_id 'Echo Shots iPad 13')}"

cd "$ROOT"
xcodegen generate
xcodebuild -project Echo.xcodeproj -scheme Echo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build -quiet

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
    # Comma-separated flags allow the arrival card to launch with a level.
    local -a launch_args
    launch_args=("${(@s:,:)arg}")
    xcrun simctl launch "$udid" "$BUNDLE" "${launch_args[@]}" >/dev/null
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
  -shot-laser 3.4 02-lasers.jpg \
  -shot-endless-deep 3.4 04-deep-time.jpg \
  -shot-arrival,-shot-level,49 8.0 05-arrival.jpg
capture "$IPHONE69" "$ROOT/docs/app-store/iphone/menu" 1320 2868 \
  -shot-worlds 1.8 03-atlas.jpg \
  -shot-research 1.8 06-research.jpg \
  -shot-shop 1.8 07-lab.jpg \
  -shot-wiki-story 1.8 08-wiki.jpg \
  -shot-home 1.8 09-home.jpg \
  -shot-recharge 1.8 10-recharge.jpg

capture "$IPHONE65" "$ROOT/docs/app-store/iphone65/play" 1284 2778 \
  -shot-play 3.4 01-gameplay.jpg \
  -shot-laser 3.4 02-lasers.jpg \
  -shot-endless-deep 3.4 04-deep-time.jpg \
  -shot-arrival,-shot-level,49 8.0 05-arrival.jpg
capture "$IPHONE65" "$ROOT/docs/app-store/iphone65/menu" 1284 2778 \
  -shot-worlds 1.8 03-atlas.jpg \
  -shot-research 1.8 06-research.jpg \
  -shot-shop 1.8 07-lab.jpg \
  -shot-wiki-story 1.8 08-wiki.jpg \
  -shot-home 1.8 09-home.jpg \
  -shot-recharge 1.8 10-recharge.jpg

capture "$IPAD13" "$ROOT/docs/app-store/ipad" 2064 2752 \
  -shot-play 3.4 01-gameplay.jpg \
  -shot-worlds,-shot-region,4 2.5 02-atlas.jpg \
  -shot-endless-deep 3.4 03-deep-time.jpg \
  -shot-research 1.8 04-research.jpg \
  -shot-shop 1.8 05-lab.jpg \
  -shot-home 6.0 06-home.jpg

echo 'iPhone and iPad screenshots refreshed; Duo and Watch have separate capture paths.'
