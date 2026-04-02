//
//  TitleBarTabStrip.swift
//  wrangle
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - Window Chrome Configurator

/// Configures the window's title bar appearance (transparent, background color).
/// No longer installs a tab strip accessory — tabs are now in the regular SwiftUI layout.
struct WindowChromeConfigurator: NSViewRepresentable {
    let appState: AppState
    let systemMetrics: SystemMetrics

    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorView()
        view.onWindow = { window in
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .visible
            window.backgroundColor = Theme.chromeBackground
            appState.nsWindow = window
            installMetricsAccessory(in: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        appState.nsWindow?.backgroundColor = Theme.chromeBackground
    }

    private func installMetricsAccessory(in window: NSWindow) {
        let hostingView = NSHostingView(rootView: SystemMetricsView(metrics: systemMetrics))
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 28))
        container.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            hostingView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = container
        accessory.layoutAttribute = .trailing

        window.addTitlebarAccessoryViewController(accessory)
    }
}

private class WindowAccessorView: NSView {
    var onWindow: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            onWindow?(window)
        }
    }
}

// MARK: - Tab Strip View

struct TitleBarTabStrip: View {
    @Environment(AppState.self) private var appState
    @State private var showTerminalPicker = false
    @State private var pendingLaunchClaude = false
    @State private var pendingLaunchGemini = false
    @State private var pendingDangerousMode = false
    @State private var draggingTabID: UUID?
    @State private var dropTargetTabID: UUID?
    @State private var isEndDropTargeted = false

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(appState.visibleTabs.enumerated()), id: \.element.id) { index, tab in
                        TitleBarTabItem(
                            tab: tab,
                            isActive: index == appState.visibleActiveIndex,
                            isPreview: tab.id == appState.previewTabID,
                            draggingTabID: $draggingTabID,
                            dropTargetTabID: $dropTargetTabID,
                            onSelect: { appState.selectVisibleTab(at: index) },
                            onClose: { appState.closeVisibleTab(at: index) },
                            onCloseAll: { appState.closeAllTabs() },
                            onPromote: {
                                if let doc = tab.document {
                                    appState.promotePreviewTab(for: doc.id)
                                }
                            },
                            onRename: { name in
                                if let session = tab.terminalSession {
                                    session.customTitle = name.isEmpty ? nil : name
                                } else {
                                    tab.customName = name.isEmpty ? nil : name
                                }
                            }
                        )
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
            .overlay(alignment: .trailing) {
                if isEndDropTargeted && draggingTabID != nil {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor)
                        .frame(width: 2)
                        .padding(.vertical, 2)
                }
            }
            .onDrop(of: [UTType.text], isTargeted: $isEndDropTargeted) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                    guard let idString = string as? String,
                          let sourceID = UUID(uuidString: idString) else { return }
                    Task { @MainActor in
                        appState.moveTabToEnd(sourceID: sourceID)
                        draggingTabID = nil
                    }
                }
                return true
            }

            // "+" menu for new tab options
            Menu {
                Button("New File") {
                    appState.newDocument()
                }
                Button("New Scratch Pad") {
                    appState.newScratchPad()
                }
                Button("New Browser") {
                    appState.openBrowser()
                }
                Divider()
                Button("New Terminal") {
                    pendingLaunchClaude = false
                    pendingLaunchGemini = false
                    pendingDangerousMode = false
                    showTerminalPicker = true
                }
                Button("New Claude Code Session") {
                    pendingLaunchClaude = true
                    pendingLaunchGemini = false
                    pendingDangerousMode = false
                    showTerminalPicker = true
                }
                Button("New Gemini Code Session") {
                    pendingLaunchClaude = false
                    pendingLaunchGemini = true
                    pendingDangerousMode = false
                    showTerminalPicker = true
                }
                Divider()
                Button {
                    pendingLaunchClaude = true
                    pendingLaunchGemini = false
                    pendingDangerousMode = true
                    showTerminalPicker = true
                } label: {
                    Label {
                        Text("Claude (Skip Permissions)")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                }
                .help("Runs claude --dangerously-skip-permissions")
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("New Tab")
            .accessibilityLabel("New tab")
            .padding(.horizontal, 6)
            .popover(isPresented: $showTerminalPicker, arrowEdge: .bottom) {
                TerminalDirectoryPicker(launchClaude: pendingLaunchClaude, launchGemini: pendingLaunchGemini, roomID: appState.selectedRoomID) { name, url, bookmarkID in
                    appState.openTerminal(
                        projectName: name,
                        directory: url,
                        bookmarkID: bookmarkID,
                        launchClaude: pendingLaunchClaude,
                        launchGemini: pendingLaunchGemini,
                        dangerousMode: pendingDangerousMode
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: Theme.chromeBackground))
    }
}

// MARK: - Tab Item

struct TitleBarTabItem: View {
    let tab: WorkspaceTab
    let isActive: Bool
    let isPreview: Bool
    @Binding var draggingTabID: UUID?
    @Binding var dropTargetTabID: UUID?
    let onSelect: () -> Void
    let onClose: () -> Void
    let onCloseAll: () -> Void
    let onPromote: () -> Void
    let onRename: (String) -> Void

    @Environment(AppState.self) private var appState
    @State private var isHovering = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isDropTargeted = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                if tab.isCustomIcon {
                    Image(tab.iconName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: tab.terminalSession?.isClaude == true ? 13 : 11, height: tab.terminalSession?.isClaude == true ? 13 : 11)
                        .foregroundColor(isActive ? tab.iconColor : .secondary)
                } else {
                    Image(systemName: tab.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(isActive ? tab.iconColor : .secondary)
                }

                Text(tab.displayName)
                    .font(.system(size: 11, weight: isActive ? .medium : .regular))
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .italic(isPreview)
                    .lineLimit(1)

                if tab.isDirty {
                    Circle()
                        .fill(.orange)
                        .frame(width: 5, height: 5)
                } else if tab.terminalSession?.needsAttention == true {
                    Circle()
                        .fill(.green)
                        .frame(width: 5, height: 5)
                }

                if (isHovering || isActive) && !tab.isRoomOverview {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Close tab")
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(minWidth: 80, maxWidth: 180)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.background.opacity(0.6))
                } else if isHovering {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.quaternary.opacity(0.5))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(
                        Color(nsColor: .separatorColor).opacity(isActive ? 1 : 0.6),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture(count: 2).onEnded { onPromote() })
        .onHover { isHovering = $0 }
        .help(tab.document?.fileURL?.path(percentEncoded: false) ?? tab.displayName)
        .animation(.easeOut(duration: 0.1), value: isActive)
        .opacity(draggingTabID == tab.id ? 0.5 : 1.0)
        .overlay {
            if isDropTargeted && draggingTabID != tab.id {
                let showTrailing: Bool = {
                    guard let dragID = draggingTabID,
                          let dragIdx = appState.tabs.firstIndex(where: { $0.id == dragID }),
                          let targetIdx = appState.tabs.firstIndex(where: { $0.id == tab.id }) else {
                        return false
                    }
                    return dragIdx < targetIdx
                }()

                HStack {
                    if showTrailing { Spacer() }
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor)
                        .frame(width: 2)
                        .padding(.vertical, 2)
                    if !showTrailing { Spacer() }
                }
                .offset(x: showTrailing ? 4 : -4)
            }
        }
        .onDrag {
            draggingTabID = tab.id
            return NSItemProvider(object: tab.id.uuidString as NSString)
        }
        .onDrop(of: [UTType.text], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                guard let idString = string as? String,
                      let sourceID = UUID(uuidString: idString) else { return }
                Task { @MainActor in
                    appState.moveTab(fromID: sourceID, toID: tab.id)
                    draggingTabID = nil
                }
            }
            return true
        }
        .contextMenu {
            if isPreview {
                Button("Keep Open") { onPromote() }
                Divider()
            }
            if tab.document?.fileURL != nil {
                Button("Show in Locations") {
                    onSelect()
                    appState.revealFileURL = tab.document?.fileURL
                }
                Button("Show in Finder") {
                    if let url = tab.document?.fileURL {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
                Divider()
            }
            Button("Rename") {
                renameText = tab.terminalSession?.customTitle ?? tab.customName ?? tab.displayName
                isRenaming = true
            }
            if !tab.isRoomOverview {
                Divider()
                Button("Close") { onClose() }
                Button("Close Others") {
                    // Close all tabs except this one
                }
                Button("Close All") { onCloseAll() }
            }
        }
        .popover(isPresented: $isRenaming, arrowEdge: .bottom) {
            VStack(spacing: 8) {
                Text("Rename Tab")
                    .font(.headline)
                TextField("Tab name", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onSubmit {
                        onRename(renameText.trimmingCharacters(in: .whitespaces))
                        isRenaming = false
                    }
                HStack {
                    Button("Cancel") {
                        isRenaming = false
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                    if tab.terminalSession?.customTitle != nil || tab.customName != nil {
                        Button("Reset") {
                            onRename("")
                            isRenaming = false
                        }
                    }
                    Button("Save") {
                        onRename(renameText.trimmingCharacters(in: .whitespaces))
                        isRenaming = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
    }
}
