import SwiftUI

struct ProjectCardView: View {
    let project: ProjectInfo
    var isCompact: Bool = false

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            // Project name
            HStack {
                Text(project.name)
                    .font(isCompact ? .caption : .headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                if project.activeTerminalCount > 0 {
                    Image(systemName: "terminal")
                        .font(isCompact ? .system(size: 8) : .caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !isCompact {
                // Git branch
                if let branch = project.gitBranch {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(branch)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let count = project.uncommittedCount, count > 0 {
                            Text("\(count) changes")
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(.yellow.opacity(0.15))
                                .foregroundStyle(.yellow)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Agent status
                HStack(spacing: 6) {
                    Circle()
                        .fill(project.agentStatus.dotColor)
                        .frame(width: 7, height: 7)
                    Text(project.agentStatus.displayText)
                        .font(.caption)
                        .foregroundStyle(project.hasRunningAgent ? .primary : .secondary)
                }
            }

            if !isCompact {
                Spacer(minLength: 0)

                // Last activity
                if !project.lastActivityText.isEmpty {
                    Text(project.lastActivityText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(isCompact ? 8 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: isCompact ? 50 : 120)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: Theme.sidebarBackground))
                .opacity(isHovered ? 1.0 : 0.8)
        }
        .overlay {
            if project.hasRunningAgent {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(project.agentStatus.dotColor.opacity(0.3), lineWidth: 1)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}
