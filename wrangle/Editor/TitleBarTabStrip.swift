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
        let desired = Theme.chromeBackground
        if appState.nsWindow?.backgroundColor != desired {
            appState.nsWindow?.backgroundColor = desired
        }
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

            // Shared creation menu — identical content across sidebar, overview, and tab strip (D-03).
            UnifiedAddMenu()
                .padding(.horizontal, 6)
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
                if tab.terminalSession?.isClaude != true && tab.terminalSession?.isGemini != true {
                    if tab.isCustomIcon {
                        Image(tab.iconName)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 11, height: 11)
                            .foregroundColor(isActive ? tab.iconColor : .secondary)
                    } else {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 10))
                            .foregroundColor(isActive ? tab.iconColor : .secondary)
                    }
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

                if (isHovering || isActive) && !tab.isProjectOverview {
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
        // Drag-to-reorder is disabled for the pinned Overview tab. It must
        // always remain at index 0 — neither moveable nor a drop target.
        // AppState.moveTab/moveTabToEnd also reject Overview as a belt-and-suspenders
        // guard, but skipping the modifiers here prevents the drag preview and drop
        // indicator from ever appearing on this tab.
        .modifier(TabReorderModifier(
            tab: tab,
            draggingTabID: $draggingTabID,
            isDropTargeted: $isDropTargeted,
            appState: appState
        ))
        .contextMenu {
            if isPreview {
                Button("Keep Open") { onPromote() }
                Divider()
            }
            if tab.document?.fileURL != nil {
                Button("Show in File Locations") {
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
            if !tab.isProjectOverview {
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

// MARK: - Tab Reorder Modifier

/// Conditionally attaches drag-source and drop-target modifiers to a tab.
/// The Project Overview tab is pinned to index 0 and must never participate
/// in drag-to-reorder, so this modifier is a no-op for it.
private struct TabReorderModifier: ViewModifier {
    let tab: WorkspaceTab
    @Binding var draggingTabID: UUID?
    @Binding var isDropTargeted: Bool
    let appState: AppState

    @ViewBuilder
    func body(content: Content) -> some View {
        if tab.isProjectOverview {
            content
        } else {
            content
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
        }
    }
}
