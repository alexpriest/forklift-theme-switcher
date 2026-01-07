#!/usr/bin/env swift

import Cocoa
import Foundation

// MARK: - Configuration

let lightThemeID = "DDA59832-D2D9-4807-BA70-67DEB3A02D52"
let darkThemeID = "2DC76F00-0EDB-4764-B1D5-D5187174A7BC"
let forkliftBundleID = "com.binarynights.ForkLift"

// MARK: - Theme Detection

func isDarkMode() -> Bool {
    UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased() == "dark"
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
        print("Forklift is not running, skipping restart")
        return
    }

    print("Restarting Forklift...")
    forklift.terminate()

    // Wait for quit, then relaunch
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let url = URL(fileURLWithPath: "/Applications/ForkLift.app")
        let config = NSWorkspace.OpenConfiguration()

        workspace.openApplication(at: url, configuration: config) { _, error in
            if let error = error {
                print("Failed to relaunch Forklift: \(error)")
            } else {
                print("Forklift relaunched")
            }
        }
    }
}

func updateTheme() {
    let targetThemeID = isDarkMode() ? darkThemeID : lightThemeID
    let currentThemeID = getCurrentTheme()

    if currentThemeID == targetThemeID {
        print("Theme already set correctly")
        return
    }

    print("Switching to \(isDarkMode() ? "dark" : "light") theme...")
    setForkliftTheme(themeID: targetThemeID)
    restartForklift()
}

// MARK: - Main

updateTheme()

DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: .main
) { _ in
    print("Appearance changed!")
    updateTheme()
}

print("Watching for appearance changes...")
RunLoop.main.run()
