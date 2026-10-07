#!/bin/zsh
set -euo pipefail

if (( $# != 1 )); then
  echo "usage: $0 path/to/Test-Echo.xcresult" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

xcrun xcresulttool export attachments --path "$1" --output-path "$TEMP" \
  --test-id 'LabCoverageTests/testDuoOuterAndInnerDisplayLayouts()' >/dev/null
mkdir -p "$ROOT/docs/app-store/duo"

for name in duo-outer-loadout duo-outer-research duo-inner-loadout duo-inner-research; do
  source_file="$(jq -r --arg name "$name" \
    '.[].attachments[] | select(.suggestedHumanReadableName | startswith($name + "_")) | .exportedFileName' \
    "$TEMP/manifest.json")"
  if [[ -z "$source_file" ]]; then
    echo "missing screenshot attachment: $name" >&2
    exit 1
  fi
  cp "$TEMP/$source_file" "$ROOT/docs/app-store/duo/$name.png"
done

echo 'Duo Lab screenshots exported at both official viewport sizes.'
