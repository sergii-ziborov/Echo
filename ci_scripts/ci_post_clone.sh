#!/bin/bash
set -euo pipefail

# Xcode Cloud checks out a clean repository. Regenerate the checked-in project
# from the same manifest used for local release builds before it archives.
export HOMEBREW_NO_AUTO_UPDATE=1
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi

cd "${CI_PRIMARY_REPOSITORY_PATH:?Xcode Cloud checkout path is required}"
xcodegen generate
