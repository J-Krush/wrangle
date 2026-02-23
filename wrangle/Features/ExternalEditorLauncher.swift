//
//  ExternalEditorLauncher.swift
//  wrangle
//

import AppKit

struct ExternalEditor: Identifiable {
    let name: String
    let bundleID: String
    var id: String { bundleID }
}

enum ExternalEditorLauncher {
    private static let knownEditors: [(name: String, bundleID: String)] = [
        ("VS Code", "com.microsoft.VSCode"),
        ("Cursor", "com.todesktop.230313mzl4w4u92"),
        ("Xcode", "com.apple.dt.Xcode"),
        ("Sublime Text", "com.sublimetext.4"),
        ("Zed", "dev.zed.Zed"),
        ("Nova", "com.panic.Nova"),
    ]

    /// Returns editors that are actually installed on this machine.
    static func availableEditors() -> [ExternalEditor] {
        knownEditors.compactMap { entry in
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.bundleID) != nil {
                return ExternalEditor(name: entry.name, bundleID: entry.bundleID)
            }
            return nil
        }
    }

    /// Opens a directory in the specified editor by bundle ID.
    static func open(directory: URL, withBundleID bundleID: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = [directory.path]
        NSWorkspace.shared.open([directory], withApplicationAt: appURL, configuration: config)
    }
}
