//
//  TitleBarTabStrip.swift
//  corral
//

import SwiftUI
import AppKit

// MARK: - Title Bar Accessory Installer

/// Installs a custom tab strip in the window's titlebar using `NSTitlebarAccessoryViewController`.
///
/// Note: `appState` is captured by value when creating the `TitleBarTabStrip` SwiftUI view
/// inside the `onWindow` closure. This works because `AppState` is a reference type injected
/// via `.environment()`, so the captured reference stays current. The `dismantleNSView` method
/// properly removes the accessory view controller when this view is torn down.
struct TitleBarAccessoryInstaller: NSViewRepresentable {
    let appState: AppState

    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorView()
        view.onWindow = { [weak coordinator = context.coordinator] window in
            guard let coordinator, !coordinator.isInstalled else { return }

            // Make titlebar transparent so tabs sit flush at top
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .visible
            window.toolbar?.isVisible = false

            let tabStrip = TitleBarTabStrip().environment(appState)
            let hostingView = NSHostingView(rootView: tabStrip)
            hostingView.translatesAutoresizingMaskIntoConstraints = false

            let accessoryVC = NSTitlebarAccessoryViewController()
            accessoryVC.view = hostingView
            accessoryVC.layoutAttribute = .bottom

            window.addTitlebarAccessoryViewController(accessoryVC)
            coordinator.isInstalled = true
            coordinator.accessoryVC = accessoryVC
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let vc = coordinator.accessoryVC, let window = nsView.window {
            if let index = window.titlebarAccessoryViewControllers.firstIndex(of: vc) {
                window.removeTitlebarAccessoryViewController(at: index)
            }
        }
        coordinator.isInstalled = false
        coordinator.accessoryVC = nil
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var isInstalled = false
        var accessoryVC: NSTitlebarAccessoryViewController?
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

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                        TitleBarTabItem(
                            tab: tab,
                            isActive: index == appState.activeTabIndex,
                            isPreview: tab.id == appState.previewTabID,
                            onSelect: { appState.selectTab(at: index) },
                            onClose: { appState.requestCloseTab(at: index) },
                            onPromote: {
                                if let doc = tab.document {
                                    appState.promotePreviewTab(for: doc.id)
                                }
                            }
                        )
                    }
                }
            }

            Spacer(minLength: 0)

            // "+" button styled as a small tab
            Button {
                appState.newDocument()
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
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.horizontal, 6)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Tab Item

struct TitleBarTabItem: View {
    let tab: WorkspaceTab
    let isActive: Bool
    let isPreview: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onPromote: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tab.iconName)
                .font(.system(size: 10))
                .foregroundColor(isActive ? tab.iconColor : .secondary)

            Text(tab.displayName)
                .font(.system(size: 11, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? .primary : .secondary)
                .italic(isPreview)
                .lineLimit(1)

            if tab.isDirty {
                Circle()
                    .fill(.orange)
                    .frame(width: 5, height: 5)
            } else if tab.isRunningTerminal {
                Circle()
                    .fill(.green)
                    .frame(width: 5, height: 5)
            }

            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
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
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onPromote() }
        .onTapGesture(count: 1, perform: onSelect)
        .onHover { isHovering = $0 }
        .animation(.spring(duration: 0.2), value: isActive)
        .draggable(tab.document?.fileURL ?? URL(filePath: "/dev/null")) {
            HStack(spacing: 4) {
                Image(systemName: tab.iconName)
                Text(tab.displayName)
            }
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .contextMenu {
            if isPreview {
                Button("Keep Open") { onPromote() }
                Divider()
            }
            Button("Close") { onClose() }
            Button("Close Others") {
                // Close all tabs except this one
            }
        }
    }
}
