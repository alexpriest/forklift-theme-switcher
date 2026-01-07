# Forklift Theme Switcher

Automatically switches [ForkLift's](https://binarynights.com/) theme to match macOS light/dark mode.

## Why?

ForkLift supports custom themes but doesn't automatically switch between them when macOS appearance changes. This utility watches for appearance changes and restarts ForkLift with the appropriate theme.

## Setup

### 1. Create your themes in ForkLift

Create both a light and dark theme in ForkLift's preferences.

### 2. Find your theme IDs

```bash
defaults read com.binarynights.ForkLift theme
```

This shows your current theme's ID. Switch to your other theme and run it again to get both IDs.

### 3. Update the script

Edit `forklift-theme-switcher.swift` and replace the theme IDs:

```swift
let lightThemeID = "YOUR-LIGHT-THEME-UUID"
let darkThemeID = "YOUR-DARK-THEME-UUID"
```

### 4. Compile

```bash
swiftc forklift-theme-switcher.swift -o forklift-theme-switcher -framework Cocoa
```

### 5. Install the Launch Agent

```bash
# Copy and edit the template
cp forklift-theme-switcher.plist.template ~/Library/LaunchAgents/forklift-theme-switcher.plist

# Edit to set your actual path
nano ~/Library/LaunchAgents/forklift-theme-switcher.plist

# Load it
launchctl load ~/Library/LaunchAgents/forklift-theme-switcher.plist
```

## Commands

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/forklift-theme-switcher.plist

# Start
launchctl load ~/Library/LaunchAgents/forklift-theme-switcher.plist

# Check status
launchctl list | grep forklift

# View logs
cat /tmp/forklift-theme-switcher.log
```

## How it works

1. Listens for `AppleInterfaceThemeChangedNotification` via `DistributedNotificationCenter`
2. Updates ForkLift's theme preference in its plist
3. Restarts ForkLift to apply the change

## License

MIT
