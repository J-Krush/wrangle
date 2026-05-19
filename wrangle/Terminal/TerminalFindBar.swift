import SwiftUI

/// Inline find-in-page bar for terminal/Claude session views. Mirrors
/// `BrowserFindBar` and `EditorFindBar` for consistency.
struct TerminalFindBar: View {
    @Bindable var session: TerminalSession
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("Find in terminal", text: $session.findQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isFocused)
                .onSubmit { session.findController?.advanceFindMatch(backwards: false) }
                .onChange(of: session.findQuery) { _, _ in
                    session.findController?.recomputeFindMatches()
                }

            Text(matchLabel)
                .font(.system(size: 10))
                .foregroundStyle(matchColor)

            Button {
                session.findCaseSensitive.toggle()
                session.findController?.recomputeFindMatches()
            } label: {
                Text("Aa")
                    .font(.system(size: 11, weight: session.findCaseSensitive ? .semibold : .regular))
                    .foregroundStyle(session.findCaseSensitive ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Case sensitive")

            Button {
                session.findController?.advanceFindMatch(backwards: true)
            } label: {
                Image(systemName: "chevron.up").font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(session.findMatches.isEmpty)
            .help("Previous")
            .keyboardShortcut(.upArrow, modifiers: [])

            Button {
                session.findController?.advanceFindMatch(backwards: false)
            } label: {
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(session.findMatches.isEmpty)
            .help("Next")
            .keyboardShortcut(.downArrow, modifiers: [])

            Button {
                session.closeFindBar()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.thinMaterial)
        .overlay(Rectangle().fill(.separator).frame(height: 1), alignment: .bottom)
        .onAppear { isFocused = true }
    }

    private var matchLabel: String {
        if session.findQuery.isEmpty { return "" }
        if session.findMatches.isEmpty { return "No matches" }
        return "\(session.findCurrentIndex + 1) of \(session.findMatches.count)"
    }

    private var matchColor: Color {
        session.findMatches.isEmpty && !session.findQuery.isEmpty ? .red : .secondary
    }
}
