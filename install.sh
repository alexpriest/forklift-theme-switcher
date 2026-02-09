#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY_NAME="forklift-theme-switcher"
BINARY_PATH="$SCRIPT_DIR/$BINARY_NAME"
PLIST_NAME="forklift-theme-switcher.plist"
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
CONFIG_PATH="$SCRIPT_DIR/config.json"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.json.template"
FORKLIFT_BUNDLE="com.binarynights.ForkLift"

# --- Discover mode: interactively find theme IDs ---
if [[ "${1:-}" == "--discover" ]]; then
    echo "=== ForkLift Theme Discovery ==="
    echo ""
    echo "This will help you find your light and dark theme IDs."
    echo ""

    # Light theme
    echo "Step 1: In ForkLift, switch to your LIGHT theme."
    echo "        (Preferences > Themes > select your light theme)"
    read -rp "Press Enter when ready..."
    LIGHT_ID=$(defaults read "$FORKLIFT_BUNDLE" theme 2>/dev/null || true)
    if [[ -z "$LIGHT_ID" ]]; then
        echo "ERROR: Could not read ForkLift theme. Is ForkLift installed?"
        exit 1
    fi
    echo "  Light theme ID: $LIGHT_ID"
    echo ""

    # Dark theme
    echo "Step 2: Now switch to your DARK theme in ForkLift."
    read -rp "Press Enter when ready..."
    DARK_ID=$(defaults read "$FORKLIFT_BUNDLE" theme 2>/dev/null || true)
    if [[ -z "$DARK_ID" ]]; then
        echo "ERROR: Could not read ForkLift theme."
        exit 1
    fi
    echo "  Dark theme ID: $DARK_ID"
    echo ""

    # Write config
    cat > "$CONFIG_PATH" <<EOF
{
    "lightThemeID": "$LIGHT_ID",
    "darkThemeID": "$DARK_ID"
}
EOF
    echo "Config written to $CONFIG_PATH"
    echo "Now run: ./install.sh"
    exit 0
fi

# --- Main install flow ---
echo "=== Installing ForkLift Theme Switcher ==="

# Check config exists
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "ERROR: config.json not found."
    echo "Either:"
    echo "  1. Run ./install.sh --discover to create it interactively"
    echo "  2. Copy config.json.template to config.json and fill in your theme IDs"
    exit 1
fi

# Unload existing agent (ignore errors if not loaded)
if launchctl list | grep -q "$BINARY_NAME" 2>/dev/null; then
    echo "Unloading existing agent..."
    launchctl bootout "gui/$(id -u)/$BINARY_NAME" 2>/dev/null || \
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Compile
echo "Compiling..."
swiftc "$SCRIPT_DIR/$BINARY_NAME.swift" -o "$BINARY_PATH" -framework Cocoa
echo "  Binary: $BINARY_PATH"

# Replace plist copy with symlink if needed
if [[ -f "$PLIST_DEST" && ! -L "$PLIST_DEST" ]]; then
    echo "Replacing plist copy with symlink..."
    rm "$PLIST_DEST"
fi

if [[ ! -L "$PLIST_DEST" ]]; then
    echo "Creating symlink..."
    ln -s "$PLIST_SOURCE" "$PLIST_DEST"
fi
echo "  Plist: $PLIST_DEST -> $PLIST_SOURCE"

# Load agent
echo "Loading agent..."
launchctl load "$PLIST_DEST"

# Verify
sleep 1
if launchctl list | grep -q "$BINARY_NAME"; then
    echo ""
    echo "Done! Agent is running."
    echo "Logs: /tmp/forklift-theme-switcher.log"
else
    echo ""
    echo "WARNING: Agent may not have started. Check:"
    echo "  launchctl list | grep forklift"
    echo "  cat /tmp/forklift-theme-switcher.log"
fi
