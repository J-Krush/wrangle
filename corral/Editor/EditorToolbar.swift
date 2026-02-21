import SwiftUI

/// A compact horizontal toolbar providing markdown formatting actions.
///
/// Uses an `EditorContext` to forward formatting commands to the underlying
/// NSTextView coordinator, so toolbar buttons directly manipulate the editor.
struct EditorToolbar: View {
    var context: EditorContext?
    @Binding var editingMode: EditingMode

    var body: some View {
        HStack(spacing: 4) {
            // --- Headings ---
            headingGroup

            Divider()
                .frame(height: 16)

            // --- Inline formatting ---
            formattingGroup

            Divider()
                .frame(height: 16)

            // --- Block elements ---
            blockGroup

            Divider()
                .frame(height: 16)

            // --- Insert elements ---
            insertGroup

            Spacer()

            // --- Editing mode toggle ---
            modeToggle
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .buttonStyle(.borderless)
        .controlSize(.small)
    }

    private var modeToggle: some View {
        Picker("", selection: $editingMode) {
            Text("Writing").tag(EditingMode.writing)
            Text("Dev").tag(EditingMode.dev)
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
        .help("Writing mode hides formatting syntax; Dev mode shows it")
    }

    // MARK: - Button Groups

    private var headingGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: "H1", icon: nil, tooltip: "Heading 1 (Cmd+1)") {
                context?.insertLinePrefix("# ")
            }
            toolbarButton(label: "H2", icon: nil, tooltip: "Heading 2 (Cmd+2)") {
                context?.insertLinePrefix("## ")
            }
            toolbarButton(label: "H3", icon: nil, tooltip: "Heading 3 (Cmd+3)") {
                context?.insertLinePrefix("### ")
            }
        }
    }

    private var formattingGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: nil, icon: "bold", tooltip: "Bold (Cmd+B)") {
                context?.insertFormatting(prefix: "**", suffix: "**")
            }
            toolbarButton(label: nil, icon: "italic", tooltip: "Italic (Cmd+I)") {
                context?.insertFormatting(prefix: "*", suffix: "*")
            }
            toolbarButton(label: nil, icon: "strikethrough", tooltip: "Strikethrough (Cmd+Shift+X)") {
                context?.insertFormatting(prefix: "~~", suffix: "~~")
            }
            toolbarButton(label: nil, icon: "chevron.left.forwardslash.chevron.right", tooltip: "Inline Code (Cmd+E)") {
                context?.insertFormatting(prefix: "`", suffix: "`")
            }
        }
    }

    private var blockGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: nil, icon: "list.bullet", tooltip: "Bullet List") {
                context?.insertLinePrefix("- ")
            }
            toolbarButton(label: nil, icon: "list.number", tooltip: "Numbered List") {
                context?.insertLinePrefix("1. ")
            }
            toolbarButton(label: nil, icon: "text.quote", tooltip: "Blockquote") {
                context?.insertLinePrefix("> ")
            }
        }
    }

    private var insertGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: nil, icon: "link", tooltip: "Link (Cmd+K)") {
                context?.insertFormatting(prefix: "[", suffix: "](url)")
            }
            toolbarButton(label: nil, icon: "minus", tooltip: "Horizontal Rule") {
                context?.insertBlock("\n---\n")
            }
            toolbarButton(label: nil, icon: "curlybraces", tooltip: "Code Block") {
                context?.insertFormatting(prefix: "```\n", suffix: "\n```")
            }
        }
    }

    // MARK: - Button Builder

    @ViewBuilder
    private func toolbarButton(
        label: String?,
        icon: String?,
        tooltip: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if let label {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .frame(minWidth: 24, minHeight: 20)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(minWidth: 24, minHeight: 20)
            }
        }
        .help(tooltip)
    }
}
