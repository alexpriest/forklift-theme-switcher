#!/usr/bin/env swift

import Cocoa

// Disable stdout buffering for immediate log output
setbuf(stdout, nil)

func log(_ message: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    print("[\(formatter.string(from: Date()))] \(message)")
}

// MARK: - Configuration

let lightThemeID = "DDA59832-D2D9-4807-BA70-67DEB3A02D52"
let darkThemeID = "2DC76F00-0EDB-4764-B1D5-D5187174A7BC"
let forkliftBundleID = "com.binarynights.ForkLift"

// MARK: - Theme Detection

func isDarkMode() -> Bool {
    NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
}

func getCurrentTheme() -> String? {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["read", forkliftBundleID, "theme"]
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Theme Switching

func setForkliftTheme(themeID: String) {
    let task = Process()
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["write", forkliftBundleID, "theme", themeID]
    task.launch()
    task.waitUntilExit()
}

func restartForklift() {
    let workspace = NSWorkspace.shared

    guard let forklift = workspace.runningApplications.first(where: { $0.bundleIdentifier == forkliftBundleID }) else {
        log("Forklift is not running, skipping restart")
        return
    }

    log("Restarting Forklift...")
    forklift.terminate()

    // Wait for quit, then relaunch
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let url = URL(fileURLWithPath: "/Applications/ForkLift.app")
        let config = NSWorkspace.OpenConfiguration()

        workspace.openApplication(at: url, configuration: config) { _, error in
            if let error = error {
                log("Failed to relaunch Forklift: \(error)")
            } else {
                log("Forklift relaunched")
            }
        }
    }
}

func updateTheme() {
    let targetThemeID = isDarkMode() ? darkThemeID : lightThemeID
    let currentThemeID = getCurrentTheme()

    if currentThemeID == targetThemeID {
        log("Theme already set correctly (\(isDarkMode() ? "dark" : "light"))")
        return
    }

    log("Switching to \(isDarkMode() ? "dark" : "light") theme...")
    setForkliftTheme(themeID: targetThemeID)
    restartForklift()
}

// MARK: - Appearance Observer

class AppearanceObserver: NSObject {
    override init() {
        super.init()
        NSApp.addObserver(self, forKeyPath: "effectiveAppearance", options: [.new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "effectiveAppearance" {
            log("Appearance changed to \(isDarkMode() ? "dark" : "light") mode")
            updateTheme()
        }
    }

    deinit {
        NSApp.removeObserver(self, forKeyPath: "effectiveAppearance")
    }
}

// MARK: - Main

// Create a minimal Cocoa app to enable KVO on appearance
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)  // No dock icon, no menu bar

// Initial check
updateTheme()

// Set up KVO observer for appearance changes (event-driven, no polling)
let observer = AppearanceObserver()
_ = observer  // Keep alive

log("Watching for appearance changes (event-driven via KVO)...")
app.run()
