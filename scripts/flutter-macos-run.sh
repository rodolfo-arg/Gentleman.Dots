#!/usr/bin/env bash
# Run Flutter app on macOS with a selected flavor and capture logs.
# Usage: scripts/flutter-macos-run.sh [-f|--flavor <name>] [--verbose] [--log <path>]

set -euo pipefail

FLAVOR="${DAP_FLUTTER_FLAVOR:-${FLAVOR:-}}"
VERBOSE=false
LOGFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--flavor)
      FLAVOR="$2"; shift 2 ;;
    --verbose|-v)
      VERBOSE=true; shift ;;
    --log)
      LOGFILE="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${FLAVOR}" ]]; then
  read -rp "Enter Flutter flavor for macOS (e.g., develop/staging/production): " FLAVOR
fi

if [[ -z "${FLAVOR}" ]]; then
  echo "Error: flavor not provided" >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter not found in PATH" >&2
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
if [[ -z "${LOGFILE}" ]]; then
  LOGFILE="./flutter-macos-${FLAVOR}-${STAMP}.log"
fi

echo "Running: flutter run -d macos --flavor '${FLAVOR}'${VERBOSE:+ -v}"
echo "Logs: ${LOGFILE}"

set -o pipefail
if [[ "${VERBOSE}" == true ]]; then
  flutter run -d macos --flavor "${FLAVOR}" -v 2>&1 | tee "${LOGFILE}"
else
  flutter run -d macos --flavor "${FLAVOR}" 2>&1 | tee "${LOGFILE}"
fi

