//
//  corralApp.swift
//  corral
//
//  Created by John Kreisher on 2/21/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct corralApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BookmarkedDirectory.self,
            RecentFile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Store is corrupted or schema changed — delete and recreate
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-shm", "-wal"] {
                let fileURL = storeURL.deletingLastPathComponent().appending(path: "default.store\(suffix)")
                try? FileManager.default.removeItem(at: fileURL)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    appState.newDocument()
                }
                .keyboardShortcut("n")

                Divider()

                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o")

                Divider()

                Button("Save") {
                    saveFile()
                }
                .keyboardShortcut("s")

                Button("Save As...") {
                    saveFileAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    withAnimation {
                        appState.sidebarWidth = appState.sidebarWidth > 0 ? 0 : 240
                    }
                }
                .keyboardShortcut("b", modifiers: [.command])
            }

            // Edit menu additions
            CommandGroup(after: .textEditing) {
                Divider()

                Button("Find in Files") {
                    appState.showGlobalSearch.toggle()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            // View menu
            CommandGroup(after: .toolbar) {
                Button("Toggle Terminal") {
                    withAnimation {
                        appState.showTerminal.toggle()
                    }
                }
                .keyboardShortcut("`", modifiers: .command)

                Divider()

                Button("Quick Open") {
                    appState.showFuzzyFinder.toggle()
                }
                .keyboardShortcut("p", modifiers: .command)
            }

            // Tab navigation
            CommandGroup(after: .windowArrangement) {
                Button("Next Tab") {
                    if appState.activeDocumentIndex < appState.openDocuments.count - 1 {
                        appState.selectDocument(at: appState.activeDocumentIndex + 1)
                    }
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Button("Previous Tab") {
                    if appState.activeDocumentIndex > 0 {
                        appState.selectDocument(at: appState.activeDocumentIndex - 1)
                    }
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("Close Tab") {
                    appState.closeDocument(at: appState.activeDocumentIndex)
                }
                .keyboardShortcut("w")
            }
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .yaml, .json]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Select files to open"

        if panel.runModal() == .OK {
            for url in panel.urls {
                appState.openFile(url: url)
            }
        }
    }

    private func saveFile() {
        guard let doc = appState.activeDocument else { return }

        if doc.fileURL != nil {
            // Already has a save location — save in place
            try? doc.save()
        } else {
            // No save location yet — prompt for one
            showSavePanel(for: doc)
        }
    }

    private func saveFileAs() {
        guard let doc = appState.activeDocument else { return }
        showSavePanel(for: doc)
    }

    private func showSavePanel(for doc: EditorDocument) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = doc.fileName
        panel.message = "Save file as"

        if panel.runModal() == .OK, let url = panel.url {
            try? doc.saveAs(to: url)
        }
    }
}
