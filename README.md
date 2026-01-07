# Forklift Theme Switcher

Automatically switches Forklift's theme to match macOS light/dark mode.

## How it works

Forklift doesn't natively support automatic theme switching for custom themes. This utility watches for macOS appearance changes and updates Forklift's theme preference, then restarts the app to apply the change.

## Setup

1. Create your light and dark themes in Forklift
2. Update the theme IDs in `forklift-theme-switcher.swift` (find them with `defaults read com.binarynights.ForkLift theme`)
3. Compile and install:

```bash
swiftc forklift-theme-switcher.swift -o forklift-theme-switcher -framework Cocoa
launchctl load ~/Library/LaunchAgents/com.anthimeros.forklift-theme-switcher.plist
```

## Commands

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.anthimeros.forklift-theme-switcher.plist

# Start
launchctl load ~/Library/LaunchAgents/com.anthimeros.forklift-theme-switcher.plist

# Logs
cat /tmp/forklift-theme-switcher.log
```

## License

MIT
