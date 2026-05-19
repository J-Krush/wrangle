import SwiftUI

/// A compact horizontal toolbar providing markdown formatting actions.
///
/// Uses an `EditorContext` to forward formatting commands to the underlying
/// NSTextView coordinator, so toolbar buttons directly manipulate the editor.
struct EditorToolbar: View {
    var context: EditorContext?
    @Binding var editingMode: EditingMode

    private var formats: ActiveFormats { context?.activeFormats ?? ActiveFormats() }

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
        HStack(spacing: 0) {
            modeButton("Writing", mode: .writing)
            modeButton("Dev", mode: .dev)
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .help("Writing mode hides formatting syntax; Dev mode shows it")
    }

    private func modeButton(_ label: String, mode: EditingMode) -> some View {
        let isSelected = editingMode == mode
        return Button {
            editingMode = mode
        } label: {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
                .background(
                    isSelected
                        ? RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.1))
                            .shadow(color: .black.opacity(0.08), radius: 1, y: 0.5)
                        : nil
                )
                .padding(2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Button Groups

    private var headingGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: "H1", icon: nil, tooltip: "Heading 1 (Cmd+Opt+1)", isActive: formats.heading == 1) {
                context?.insertLinePrefix("# ")
            }
            toolbarButton(label: "H2", icon: nil, tooltip: "Heading 2 (Cmd+Opt+2)", isActive: formats.heading == 2) {
                context?.insertLinePrefix("## ")
            }
            toolbarButton(label: "H3", icon: nil, tooltip: "Heading 3 (Cmd+Opt+3)", isActive: formats.heading == 3) {
                context?.insertLinePrefix("### ")
            }
        }
    }

    private var formattingGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: nil, icon: "bold", tooltip: "Bold (Cmd+B)", isActive: formats.bold) {
                context?.insertFormatting(prefix: "**", suffix: "**")
            }
            toolbarButton(label: nil, icon: "italic", tooltip: "Italic (Cmd+I)", isActive: formats.italic) {
                context?.insertFormatting(prefix: "*", suffix: "*")
            }
            toolbarButton(label: nil, icon: "strikethrough", tooltip: "Strikethrough (Cmd+Shift+X)", isActive: formats.strikethrough) {
                context?.insertFormatting(prefix: "~~", suffix: "~~")
            }
            toolbarButton(label: nil, icon: "chevron.left.forwardslash.chevron.right", tooltip: "Inline Code (Cmd+E)", isActive: formats.inlineCode) {
                context?.insertFormatting(prefix: "`", suffix: "`")
            }
            toolbarButton(label: nil, icon: "curlybraces", tooltip: "Code Block", isActive: formats.codeBlock) {
                context?.insertFormatting(prefix: "```\n", suffix: "\n```")
            }
        }
    }

    private var blockGroup: some View {
        HStack(spacing: 2) {
            toolbarButton(label: nil, icon: "list.bullet", tooltip: "Bullet List", isActive: formats.bulletList) {
                context?.insertLinePrefix("- ")
            }
            Menu {
                Button("1, 2, 3...") {
                    context?.insertLinePrefix("1. ")
                    context?.setOrderedListStyle(.numeric)
                }
                Button("a, b, c...") {
                    context?.insertLinePrefix("a. ")
                    context?.setOrderedListStyle(.lowerAlpha)
                }
                Button("A, B, C...") {
                    context?.insertLinePrefix("A. ")
                    context?.setOrderedListStyle(.upperAlpha)
                }
                Button("i, ii, iii...") {
                    context?.insertLinePrefix("i. ")
                    context?.setOrderedListStyle(.lowerRoman)
                }
                Button("I, II, III...") {
                    context?.insertLinePrefix("I. ")
                    context?.setOrderedListStyle(.upperRoman)
                }
            } label: {
                Image(systemName: "list.number")
                    .font(.system(size: 12))
                    .frame(minWidth: 24, minHeight: 20)
            } primaryAction: {
                context?.insertLinePrefix("1. ")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .foregroundStyle(formats.numberedList ? Color.accentColor : .primary)
            .help("Numbered List (click-hold for styles)")
            toolbarButton(label: nil, icon: "text.quote", tooltip: "Blockquote", isActive: formats.blockquote) {
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
        }
    }

    // MARK: - Button Builder

    @ViewBuilder
    private func toolbarButton(
        label: String?,
        icon: String?,
        tooltip: String,
        isActive: Bool = false,
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
        .foregroundStyle(isActive ? Color.accentColor : .primary)
        .background(
            isActive
                ? RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.2))
                : RoundedRectangle(cornerRadius: 4).fill(Color.clear)
        )
        .help(tooltip)
    }
}
