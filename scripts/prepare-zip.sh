#!/usr/bin/env bash
#
# Vendor-copies @percy/maestro-app/percy into flows/percy, then zips flows/
# into Flows.zip for upload to the BrowserStack Maestro v2 build API.
#
# Mirrors the recommended "Mode B" pattern from the @percy/maestro-app README.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_PERCY="$ROOT_DIR/node_modules/@percy/maestro-app/percy"
FLOWS_DIR="$ROOT_DIR/flows"
ZIP_OUT="$ROOT_DIR/Flows.zip"

if [ ! -d "$SDK_PERCY" ]; then
  echo "Error: $SDK_PERCY not found." >&2
  echo "Run 'npm install' first." >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: 'zip' is not installed." >&2
  echo "Install it with your package manager (e.g. 'brew install zip')." >&2
  exit 1
fi

rm -rf "$FLOWS_DIR/percy"
cp -r "$SDK_PERCY" "$FLOWS_DIR/percy"

rm -f "$ZIP_OUT"
# Zip with `flows/` as the single top-level directory.
# BrowserStack Maestro v2 requires the test-suite zip's root to be a single
# parent directory containing the flows; otherwise the scanner fails with
# "Top-level directories do not contain any Flows".
(cd "$ROOT_DIR" && zip -rq "$ZIP_OUT" flows)

echo "Wrote $ZIP_OUT (contains flows/: $(cd "$FLOWS_DIR" && find . -name '*.yaml' -not -path '*/percy/*' | sed 's|^\./||' | tr '\n' ' '))"
echo
echo "Upload the zip to BrowserStack:"
echo "  curl -u \"\$BROWSERSTACK_USERNAME:\$BROWSERSTACK_ACCESS_KEY\" \\"
echo "       -X POST 'https://api-cloud.browserstack.com/app-automate/maestro/v2/test-suite' \\"
echo "       -F 'file=@Flows.zip'"
