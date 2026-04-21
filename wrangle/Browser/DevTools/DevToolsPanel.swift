//
//  DevToolsPanel.swift
//  Wrangle
//

import SwiftUI

struct DevToolsPanel: View {
    let session: BrowserSession

    var body: some View {
        VStack(spacing: 0) {
            // Resize handle
            DevToolsResizeHandle(height: Binding(
                get: { session.devToolsHeight },
                set: { session.devToolsHeight = $0 }
            ))

            // Toolbar with tab selector
            HStack(spacing: 0) {
                ForEach(DevToolType.allCases, id: \.self) { tool in
                    Button {
                        session.activeDevTool = tool
                    } label: {
                        Text(tool.rawValue)
                            .font(.system(size: 11, weight: session.activeDevTool == tool ? .semibold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(session.activeDevTool == tool ? Color.accentColor.opacity(0.15) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    session.isDevToolsVisible = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Developer Tools")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: Theme.chromeBackground))

            Divider()

            // Active panel
            Group {
                switch session.activeDevTool {
                case .console:
                    ConsoleView(session: session)
                case .cookies:
                    CookieManagerView(session: session)
                case .network:
                    NetworkInspectorView(session: session)
                case .elements:
                    ElementInspectorView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Resize Handle

private struct DevToolsResizeHandle: View {
    @Binding var height: CGFloat
    @State private var startHeight: CGFloat?

    var body: some View {
        ResizeHandle(
            axis: .vertical,
            onDragged: { translation in
                if startHeight == nil { startHeight = height }
                // AppKit y-up: drag up → positive translation → increase height
                height = max(100, min(600, (startHeight ?? height) + translation))
            },
            onEnded: { startHeight = nil }
        )
        .frame(height: 5)
    }
}
