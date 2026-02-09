#!/bin/bash
set -euo pipefail

# Install Flexoki Light and Dark themes into ForkLift 4
# Re-runnable: removes existing Flexoki themes before adding fresh copies

DOMAIN="com.binarynights.ForkLift"
LIGHT_ID="A1B2C3D4-1111-4000-8000-F1EC01110001"
DARK_ID="A1B2C3D4-2222-4000-8000-F1EC01DA2C01"

echo "Installing Flexoki themes for ForkLift 4..."

# Quit ForkLift if running
if pgrep -x "ForkLift" > /dev/null 2>&1; then
    echo "Quitting ForkLift..."
    osascript -e 'tell application "ForkLift" to quit'
    sleep 1
fi

# Use python3 to read existing themes, merge, and write back
python3 << 'PYTHON_SCRIPT'
import subprocess
import plistlib
import json
import sys
import base64

DOMAIN = "com.binarynights.ForkLift"
LIGHT_ID = "A1B2C3D4-1111-4000-8000-F1EC01110001"
DARK_ID = "A1B2C3D4-2222-4000-8000-F1EC01DA2C01"

def color(r, g, b):
    return {"red": r / 255.0, "green": g / 255.0, "blue": b / 255.0, "alpha": 1.0}

flexoki_light = {
    "id": LIGHT_ID,
    "name": "Flexoki Light",
    "editable": True,
    "darkStyle": False,
    "baseColor": color(0xFF, 0xFC, 0xF0),
    "sidebarColor": color(0xF2, 0xF0, 0xE5),
    "sidebarItemColor": color(0x10, 0x0F, 0x0F),
    "sidebarSelectionColor": color(0xDA, 0xD8, 0xCE),
    "sidebarTextColor": color(0x10, 0x0F, 0x0F),
    "textColor": color(0x10, 0x0F, 0x0F),
    "secondaryTextColor": color(0x6F, 0x6E, 0x69),
    "highlightColor": color(0x43, 0x85, 0xBE),
}

flexoki_dark = {
    "id": DARK_ID,
    "name": "Flexoki Dark",
    "editable": True,
    "darkStyle": True,
    "baseColor": color(0x10, 0x0F, 0x0F),
    "sidebarColor": color(0x28, 0x27, 0x26),
    "sidebarItemColor": color(0xCE, 0xCD, 0xC3),
    "sidebarSelectionColor": color(0x40, 0x3E, 0x3C),
    "sidebarTextColor": color(0xCE, 0xCD, 0xC3),
    "textColor": color(0xCE, 0xCD, 0xC3),
    "secondaryTextColor": color(0x87, 0x85, 0x80),
    "highlightColor": color(0x43, 0x85, 0xBE),
}

# Read existing themes from defaults
existing_themes = []
try:
    result = subprocess.run(
        ["defaults", "export", DOMAIN, "-"],
        capture_output=True, check=True
    )
    plist = plistlib.loads(result.stdout)
    if "themes" in plist:
        themes_data = plist["themes"]
        if isinstance(themes_data, bytes):
            # ForkLift stores themes as JSON bytes
            existing_themes = json.loads(themes_data)
        elif isinstance(themes_data, list):
            existing_themes = themes_data
except (subprocess.CalledProcessError, Exception) as e:
    print(f"No existing themes found (starting fresh): {e}")
    existing_themes = []

# Remove any existing Flexoki themes (by name or id)
flexoki_ids = {LIGHT_ID, DARK_ID}
flexoki_names = {"Flexoki Light", "Flexoki Dark"}
existing_themes = [
    t for t in existing_themes
    if t.get("id") not in flexoki_ids and t.get("name") not in flexoki_names
]

# Append new themes
existing_themes.append(flexoki_light)
existing_themes.append(flexoki_dark)

# Encode as JSON bytes and write via defaults using <data> format (same as catppuccin)
json_bytes = json.dumps(existing_themes, separators=(",", ":")).encode("utf-8")
b64 = base64.b64encode(json_bytes).decode("ascii")
plist_value = f"<data>{b64}</data>"
subprocess.run(
    ["defaults", "write", DOMAIN, "themes", plist_value],
    check=True
)

print(f"Wrote {len(existing_themes)} total themes ({len(existing_themes) - 2} existing + 2 Flexoki)")
PYTHON_SCRIPT

echo ""
echo "Flexoki Light and Dark themes installed."
echo "Relaunch ForkLift and go to Settings > Themes to select them."
