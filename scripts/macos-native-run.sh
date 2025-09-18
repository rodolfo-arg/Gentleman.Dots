#!/usr/bin/env bash
# Build and run a macOS app natively with xcodebuild, capturing logs.
# Works with Flutter macOS projects too, using your custom Xcode scheme.
#
# Usage:
#   scripts/macos-native-run.sh [--scheme <name>] [--config <cfg>] [--open]
#                               [--log <path>] [--project <.xcodeproj> | --workspace <.xcworkspace>]
#                               [--path <proj_dir>] [--verbose] [--] [app args...]
#
# Env fallbacks:
#   DAP_XCODE_SCHEME, DAP_XCODE_CONFIG

set -euo pipefail

SCHEME="${DAP_XCODE_SCHEME:-}"
CONFIG="${DAP_XCODE_CONFIG:-}"
VERBOSE=false
OPEN_APP=false
LOGFILE=""
PROJ_DIR=""
EXPL_WORKSPACE=""
EXPL_PROJECT=""
BUILD_ONLY=false

APP_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scheme|-s) SCHEME="$2"; shift 2 ;;
    --config|-c) CONFIG="$2"; shift 2 ;;
    --log) LOGFILE="$2"; shift 2 ;;
    --open) OPEN_APP=true; shift ;;
    --verbose|-v) VERBOSE=true; shift ;;
    --workspace) EXPL_WORKSPACE="$2"; shift 2 ;;
    --project) EXPL_PROJECT="$2"; shift 2 ;;
    --path) PROJ_DIR="$2"; shift 2 ;;
    --build-only|-b) BUILD_ONLY=true; shift ;;
    --) shift; APP_ARGS=("$@"); break ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Error: xcodebuild not found. Install Xcode Command Line Tools." >&2
  exit 1
fi

# Detect project directory (default to ./macos if present)
if [[ -z "${PROJ_DIR}" ]]; then
  if [[ -d ./macos ]]; then
    PROJ_DIR="./macos"
  else
    PROJ_DIR="."
  fi
fi

if [[ -z "${SCHEME}" ]]; then
  read -rp "Xcode scheme (e.g., develop/staging/production): " SCHEME
fi
if [[ -z "${SCHEME}" ]]; then
  echo "Error: scheme not provided" >&2
  exit 1
fi

# Determine workspace/project flags
BUILD_DIR_FLAGS=()
if [[ -n "${EXPL_WORKSPACE}" ]]; then
  BUILD_DIR_FLAGS=( -workspace "${EXPL_WORKSPACE}" )
elif [[ -n "${EXPL_PROJECT}" ]]; then
  BUILD_DIR_FLAGS=( -project "${EXPL_PROJECT}" )
elif [[ -d "${PROJ_DIR}/Runner.xcworkspace" ]]; then
  BUILD_DIR_FLAGS=( -workspace Runner.xcworkspace )
elif [[ -d "${PROJ_DIR}/Runner.xcodeproj" ]]; then
  BUILD_DIR_FLAGS=( -project Runner.xcodeproj )
else
  echo "Error: Could not find Runner.xcworkspace or Runner.xcodeproj under ${PROJ_DIR}. Use --workspace/--project." >&2
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
if [[ -z "${LOGFILE}" ]]; then
  LOGFILE="./macos-native-${SCHEME}-${CONFIG}-${STAMP}.log"
fi

cd "${PROJ_DIR}"

SHOW_FLAGS=( -scheme "${SCHEME}" -sdk macosx )
if [[ -n "${CONFIG}" ]]; then
  SHOW_FLAGS+=( -configuration "${CONFIG}" )
fi
[[ "${VERBOSE}" == true ]] && SHOW_FLAGS+=( -showBuildTimingSummary )

echo "[1/3] Reading build settings..." | tee "${LOGFILE}"
set -o pipefail
SETTINGS=$(xcodebuild -showBuildSettings "${BUILD_DIR_FLAGS[@]}" "${SHOW_FLAGS[@]}" 2>&1 | tee -a "${LOGFILE}")
BS_FILE="${LOGFILE%.log}-build-settings.log"
printf "%s\n" "${SETTINGS}" > "${BS_FILE}"
echo "Saved build settings to: ${BS_FILE}" | tee -a "${LOGFILE}"

# Validate configuration exists (best-effort)
if command -v xcodebuild >/dev/null 2>&1; then
  echo "Available configurations for scheme '${SCHEME}':" | tee -a "${LOGFILE}"
  xcodebuild -list -json "${BUILD_DIR_FLAGS[@]}" 2>/dev/null | tee -a "${LOGFILE}" >/dev/null || true
fi

BUILT_PRODUCTS_DIR=$(printf "%s\n" "${SETTINGS}" | sed -n 's/^ *BUILT_PRODUCTS_DIR = //p' | tail -1)
EXECUTABLE_PATH=$(printf "%s\n" "${SETTINGS}" | sed -n 's/^ *EXECUTABLE_PATH = //p' | tail -1)
FULL_PRODUCT_NAME=$(printf "%s\n" "${SETTINGS}" | sed -n 's/^ *FULL_PRODUCT_NAME = //p' | tail -1)
CONFIGURATION_BUILD_DIR=$(printf "%s\n" "${SETTINGS}" | sed -n 's/^ *CONFIGURATION_BUILD_DIR = //p' | tail -1)

if [[ -z "${BUILT_PRODUCTS_DIR}" || -z "${EXECUTABLE_PATH}" || -z "${FULL_PRODUCT_NAME}" ]]; then
  echo "Error: Missing expected build settings (BUILT_PRODUCTS_DIR/EXECUTABLE_PATH/FULL_PRODUCT_NAME)." | tee -a "${LOGFILE}"
  exit 1
fi

APP_DIR="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
BIN_PATH="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_PATH}"

echo "[2/3] Building app: scheme='${SCHEME}' ${CONFIG:+config='${CONFIG}'}" | tee -a "${LOGFILE}"
BUILD_FLAGS=( -scheme "${SCHEME}" -sdk macosx build )
if [[ -n "${CONFIG}" ]]; then
  BUILD_FLAGS+=( -configuration "${CONFIG}" )
fi
[[ "${VERBOSE}" == true ]] && BUILD_FLAGS+=( -showBuildTimingSummary )

set -o pipefail
xcodebuild "${BUILD_DIR_FLAGS[@]}" "${BUILD_FLAGS[@]}" 2>&1 | tee -a "${LOGFILE}"

if [[ "${BUILD_ONLY}" == true ]]; then
  echo "[3/3] Build-only requested. Skipping launch." | tee -a "${LOGFILE}"
  exit 0
fi

echo "[3/3] Launching app…" | tee -a "${LOGFILE}"
if [[ "${OPEN_APP}" == true ]]; then
  echo "open \"${APP_DIR}\"" | tee -a "${LOGFILE}"
  open "${APP_DIR}"
  echo "Launched via 'open'. Logs may appear in Console.app." | tee -a "${LOGFILE}"
else
  echo "${BIN_PATH} ${APP_ARGS[*]:-}" | tee -a "${LOGFILE}"
  "${BIN_PATH}" "${APP_ARGS[@]:-}" 2>&1 | tee -a "${LOGFILE}"
fi
