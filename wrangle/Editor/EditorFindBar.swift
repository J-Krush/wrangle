import SwiftUI

/// Inline find-in-page bar for the markdown editor. Mirrors `BrowserFindBar`
/// for visual and keyboard parity.
struct EditorFindBar: View {
    @Bindable var context: EditorContext
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("Find on page", text: $context.findQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($isFocused)
                .onSubmit { context.advanceMatch() }
                .onChange(of: context.findQuery) { _, _ in context.recomputeMatches() }

            Text(matchLabel)
                .font(.system(size: 10))
                .foregroundStyle(matchColor)

            Button {
                context.findCaseSensitive.toggle()
                context.recomputeMatches()
            } label: {
                Text("Aa")
                    .font(.system(size: 11, weight: context.findCaseSensitive ? .semibold : .regular))
                    .foregroundStyle(context.findCaseSensitive ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Case sensitive")

            Button {
                context.advanceMatch(backwards: true)
            } label: {
                Image(systemName: "chevron.up").font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(context.findMatches.isEmpty)
            .help("Previous")
            .keyboardShortcut(.upArrow, modifiers: [])

            Button {
                context.advanceMatch()
            } label: {
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            .disabled(context.findMatches.isEmpty)
            .help("Next")
            .keyboardShortcut(.downArrow, modifiers: [])

            Button {
                context.closeFindBar()
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
        if context.findQuery.isEmpty { return "" }
        if context.findMatches.isEmpty { return "No matches" }
        return "\(context.findCurrentIndex + 1) of \(context.findMatches.count)"
    }

    private var matchColor: Color {
        context.findMatches.isEmpty && !context.findQuery.isEmpty ? .red : .secondary
    }
}
