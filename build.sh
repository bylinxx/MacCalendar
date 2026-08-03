#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/MacCalendar.xcodeproj"
SCHEME="MacCalendar"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$PROJECT_DIR/.derived"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
  debug         Build Debug (default)
  release       Build Release (unsigned)
  dmg           Build Release + package .dmg
  run           Build Debug and start the app
  clean         Clean build folder
  help          Show this help

Options:
  --arch native     Build for current CPU only (default for debug)
  --arch universal  Build universal binary (default for release/dmg)
  -v, --verbose     Show full xcodebuild output

Examples:
  ./build.sh debug --arch universal
  ./build.sh release --arch native
  ./build.sh dmg -v
EOF
    exit 0
}

log()     { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
info()    { echo -e "${CYAN}[i]${NC} $1"; }
err()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ----- Parse arguments -----
CMD="${1:-debug}"
ARCH=""
VERBOSE=""

case "$CMD" in
    debug|release|dmg|run|clean|help) shift ;;
    -v|--verbose) CMD="debug"; VERBOSE="-v" ;;
    *) usage ;;
esac

while [ $# -gt 0 ]; do
    case "$1" in
        --arch) ARCH="$2"; shift 2 ;;
        -v|--verbose) VERBOSE="-v"; shift ;;
        *) usage ;;
    esac
done

# ----- Early exit for help / clean -----
if [ "$CMD" = "help" ]; then usage; fi

if [ "$CMD" = "clean" ]; then
    info "Cleaning build artifacts..."
    rm -rf "$PROJECT_DIR/build" "$PROJECT_DIR/.derived"
    xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -quiet 2>/dev/null || true
    log "Cleaned"
    exit 0
fi

# ----- Determine architecture -----
CURRENT_ARCH=$(uname -m)  # arm64 or x86_64

if [ -z "$ARCH" ]; then
    case "$CMD" in
        debug|run)  ARCH="native" ;;
        release|dmg) ARCH="universal" ;;
    esac
fi

case "$ARCH" in
    native)
        ARCH_FLAGS=()
        ARCH_TAG="$CURRENT_ARCH"
        ;;
    universal)
        ARCH_FLAGS=(-arch x86_64 -arch arm64)
        ARCH_TAG="universal"
        ;;
    x86_64)
        ARCH_FLAGS=(-arch x86_64)
        ARCH_TAG="x86_64"
        ;;
    arm64)
        ARCH_FLAGS=(-arch arm64)
        ARCH_TAG="arm64"
        ;;
    *) err "Unknown arch: $ARCH (use native, universal, x86_64, arm64)" ;;
esac

# Derived build dir per arch
BUILD_DIR="$BUILD_DIR/$ARCH_TAG"
DERIVED_DATA="$DERIVED_DATA/$ARCH_TAG"

XCODE=$(xcode-select -p 2>/dev/null) || err "Xcode not found (xcode-select -p failed)"

XCB_FLAGS=(
    -project "$PROJECT"
    -scheme "$SCHEME"
    -destination 'platform=macOS'
    "${ARCH_FLAGS[@]}"
    SYMROOT="$BUILD_DIR"
    OBJROOT="$DERIVED_DATA"
)

# ----- Commands -----
if [ "$CMD" = "debug" ] || [ "$CMD" = "run" ]; then
    info "Building Debug [${ARCH_TAG}]..."
    set -x
    xcodebuild build "${XCB_FLAGS[@]}" \
        -configuration Debug \
        ${VERBOSE:+--verbose} 2>&1 | tee "$BUILD_DIR/build.log"
    { set +x; } 2>/dev/null
    log "Debug build succeeded → $BUILD_DIR/Debug/MacCalendar.app"

    if [ "$CMD" = "run" ]; then
        "$BUILD_DIR/Debug/MacCalendar.app/Contents/MacOS/MacCalendar" &
        log "App launched"
    fi
    exit 0
fi

if [ "$CMD" = "release" ] || [ "$CMD" = "dmg" ]; then
    info "Building Release [${ARCH_TAG}] (unsigned)..."
    set -x
    xcodebuild clean build "${XCB_FLAGS[@]}" \
        -configuration Release \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=YES \
        ${VERBOSE:+--verbose} 2>&1 | tee "$BUILD_DIR/build.log"
    { set +x; } 2>/dev/null

    APP_PATH="$BUILD_DIR/Release/MacCalendar.app"
    [ -d "$APP_PATH" ] || err "App not found at $APP_PATH"

    # Verify binary arch
    BINARY="$APP_PATH/Contents/MacOS/MacCalendar"
    if [ -f "$BINARY" ]; then
        ARCHS=$(lipo -info "$BINARY" 2>/dev/null | awk -F': ' '{print $NF}')
        log "Binary architectures: $ARCHS"
    fi

    log "Release build succeeded → $APP_PATH"

    if [ "$CMD" = "dmg" ]; then
        DMG_NAME="MacCalendar.dmg"
        info "Creating DMG..."
        if ! command -v create-dmg &>/dev/null; then
            warn "create-dmg not found, installing..."
            brew install create-dmg
        fi
        DMG_SRC="$BUILD_DIR/dmg_source"

        rm -rf "$DMG_SRC"
        mkdir -p "$DMG_SRC"
        cp -r "$APP_PATH" "$DMG_SRC/"

        create-dmg \
            --volname "MacCalendar Installer" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "MacCalendar.app" 150 120 \
            --hide-extension "MacCalendar.app" \
            --app-drop-link 450 120 \
            "$BUILD_DIR/$DMG_NAME" \
            "$DMG_SRC/" 2>&1 | tee -a "$BUILD_DIR/build.log"

        rm -rf "$DMG_SRC"
        log "DMG created → $BUILD_DIR/$DMG_NAME"
    fi
    exit 0
fi

usage