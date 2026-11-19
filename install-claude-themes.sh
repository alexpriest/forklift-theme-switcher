#!/bin/bash
set -euo pipefail

# Install Claude Light and Dark themes into ForkLift 4, in the theme IDs the switcher watches.
# Palette: the Claude desktop app's own tokens (bg-100/200/400, text-000/300/400, brand-000).
# Surfaces are opaque, matching Bartleby and Claude. Re-runnable. The Flexoki copies this
# replaces are kept under new IDs; install-flexoki-themes.sh reverts the switcher IDs to Flexoki.

if pgrep -x ForkLift > /dev/null 2>&1; then
    osascript -e 'tell application "ForkLift" to quit'
    for _ in $(seq 1 20); do pgrep -x ForkLift > /dev/null || break; sleep 0.5; done
fi

HEX=$(python3 -I - << 'PYTHON_SCRIPT'
import colorsys, json, plistlib, subprocess
LIGHT_ID = "A1B2C3D4-1111-4000-8000-F1EC01110001"
DARK_ID = "A1B2C3D4-2222-4000-8000-F1EC01DA2C01"
KEEP = {LIGHT_ID: "A1B2C3D4-3333-4000-8000-F1EC01110003", DARK_ID: "A1B2C3D4-4444-4000-8000-F1EC01DA2C04"}

def hsl(h: float, s: float, l: float) -> dict:
    r, g, b = colorsys.hls_to_rgb(h / 360, l / 100, s / 100)
    return {"red": r, "green": g, "blue": b, "alpha": 1}

CLAY = hsl(15, 54.2, 51.2)  # #C6613F
THEMES = {
    LIGHT_ID: dict(name="Claude Light", darkStyle=False, editable=True,
        baseColor=hsl(48, 33.3, 97.1), sidebarColor=hsl(53, 28.6, 94.5),
        sidebarSelectionColor=hsl(50, 20.7, 88.6), textColor=hsl(60, 2.6, 7.6),
        secondaryTextColor=hsl(51, 3.1, 43.7), sidebarTextColor=hsl(60, 2.6, 7.6),
        sidebarItemColor=hsl(60, 2.5, 23.3), highlightColor=CLAY),
    DARK_ID: dict(name="Claude Dark", darkStyle=True, editable=True,
        baseColor=hsl(60, 2.7, 14.5), sidebarColor=hsl(30, 3.3, 11.8),
        sidebarSelectionColor=hsl(60, 2.1, 18.4), textColor=hsl(48, 33.3, 97.1),
        secondaryTextColor=hsl(48, 4.8, 59.2), sidebarTextColor=hsl(48, 33.3, 97.1),
        sidebarItemColor=hsl(50, 9, 73.7), highlightColor=CLAY),
}
raw = subprocess.run(["defaults", "export", "com.binarynights.ForkLift", "-"], capture_output=True).stdout
existing = json.loads(plistlib.loads(raw).get("themes", b"[]")) if raw else []
out, kept = [], {t["id"] for t in existing}
for t in existing:
    if t["id"] in THEMES:
        if not t.get("name", "").startswith("Claude") and KEEP[t["id"]] not in kept:
            out.append(dict(t, id=KEEP[t["id"]]))
        continue
    out.append(t)
out += [dict(v, id=k) for k, v in THEMES.items()]
print(json.dumps(out, separators=(",", ":")).encode().hex())
PYTHON_SCRIPT
)
defaults write com.binarynights.ForkLift themes -data "$HEX"
echo "Claude themes installed. Relaunch ForkLift to see them."
