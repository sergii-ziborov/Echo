#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${ECHO_SHOT_DERIVED:-/tmp/EchoLabShotBuild}"
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

cd "$ROOT"
xcodebuild -project Echo.xcodeproj -scheme Echo -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO build -quiet

capture() {
  local device="$1" folder="$2" research="$3" lab="$4" recharge="$5"
  xcrun simctl boot "$device" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device" -b >/dev/null
  xcrun simctl install "$device" "$APP"
  xcrun simctl status_bar "$device" override --time '9:41' \
    --batteryLevel 100 --cellularBars 4 --wifiBars 3 >/dev/null 2>&1 || true

  local flag file
  local shots=("-shot-research:$research" "-shot-shop:$lab")
  if [[ "$recharge" != "-" ]]; then
    shots+=("-shot-recharge:$recharge")
  fi
  for pair in "${shots[@]}"; do
    flag="${pair%%:*}"
    file="${pair#*:}"
    xcrun simctl terminate "$device" "$BUNDLE" >/dev/null 2>&1 || true
    xcrun simctl launch "$device" "$BUNDLE" "$flag" >/dev/null
    sleep 2
    xcrun simctl io "$device" screenshot "$folder/$file.png" >/dev/null
    sips -s format jpeg -s formatOptions 90 "$folder/$file.png" --out "$folder/$file.jpg" >/dev/null
    rm "$folder/$file.png"
  done
}

capture "${IPHONE69:-$(simulator_id 'Echo Shots 6.9')}" \
  "$ROOT/docs/app-store/iphone/menu" 06-research 07-lab 10-recharge
capture "${IPHONE65:-$(simulator_id 'Echo Shots 6.5')}" \
  "$ROOT/docs/app-store/iphone65/menu" 06-research 07-lab 10-recharge
capture "${IPAD13:-$(simulator_id 'Echo Shots iPad 13')}" \
  "$ROOT/docs/app-store/ipad" 04-research 05-lab -

echo 'Lab screenshots captured from the running app.'
