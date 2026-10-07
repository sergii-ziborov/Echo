#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${ECHO_SHOT_DERIVED:-/tmp/EchoWatchShotBuild}"
APP="$DERIVED/Build/Products/Debug-watchsimulator/EchoWatch.app"
BUNDLE=com.sergiiziborov.Echo.watchkitapp
DEST="$ROOT/docs/app-store/watch"

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

WATCH="${WATCH:-$(simulator_id 'Echo Shots Watch 46')}"

cd "$ROOT"
xcodebuild -project Echo.xcodeproj -scheme EchoWatch -configuration Debug \
  -destination "platform=watchOS Simulator,id=$WATCH" -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO build -quiet

mkdir -p "$DEST"
xcrun simctl boot "$WATCH" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$WATCH" -b >/dev/null
xcrun simctl install "$WATCH" "$APP"
xcrun simctl status_bar "$WATCH" override --time '9:41' >/dev/null 2>&1 || true

capture() {
  local flags="$1" wait="$2" file="$3"
  local -a launch_args
  launch_args=("${(@s:,:)flags}")
  xcrun simctl terminate "$WATCH" "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl launch "$WATCH" "$BUNDLE" "${launch_args[@]}" >/dev/null
  sleep "$wait"
  xcrun simctl io "$WATCH" screenshot /tmp/echo-watch-shot-raw.png >/dev/null
  sips -s format jpeg -s formatOptions 90 /tmp/echo-watch-shot-raw.png --out "$DEST/$file" >/dev/null
  echo "wrote $DEST/$file"
}

capture '-wrist-unlock-all,-wrist-map,8,-wrist-autopilot' 8 01-wrist-run.jpg
capture '-wrist-unlock-all,-wrist-maps' 3 02-wrist-maps.jpg
capture '-wrist-unlock-all,-wrist-relics' 3 03-relics.jpg
capture '-wrist-unlock-all,-wrist-skills' 3 04-skills.jpg
