# forklift-theme-switcher

Switches ForkLift's theme when macOS switches between light and dark, which ForkLift does not do on its own.

## Status

Shipped — watches macOS appearance and restarts ForkLift with the matching theme.

## License

Not licensed for reuse.

## Why?

ForkLift supports custom themes but doesn't automatically switch between them when macOS appearance changes. This utility watches for appearance changes and restarts ForkLift with the appropriate theme.

## Quick Setup

### 1. Create your themes in ForkLift

Create both a light and dark theme in ForkLift's preferences.

### 2. Discover your theme IDs

```bash
./install.sh --discover
```

This walks you through selecting each theme in ForkLift and writes `config.json` automatically.

### 3. Install

```bash
./install.sh
```

Compiles the binary, symlinks the LaunchAgent, and starts it.

## Manual Setup

If you prefer to set up manually:

1. Copy `config.json.template` to `config.json`
2. Find your theme IDs by switching themes and running:
   ```bash
   defaults read com.binarynights.ForkLift theme
   ```
3. Fill in the IDs in `config.json`
4. Run `./install.sh`

## Machine Sync

The source code and plist sync between machines via Syncthing. `config.json` is per-machine (gitignored + stignored) since theme UUIDs differ. On a new machine, just run `./install.sh --discover` then `./install.sh`.

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

1. Reads theme IDs from `config.json` at startup
2. Watches for macOS appearance changes via KVO on `NSApp.effectiveAppearance`
3. Updates ForkLift's theme preference via `defaults write`
4. Restarts ForkLift to apply the change

## License

MIT
