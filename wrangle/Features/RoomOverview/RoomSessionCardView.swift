import SwiftUI

struct RoomSessionCardView: View {
    let item: RoomSessionItem

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: icon + title
            HStack(spacing: 8) {
                if item.isCustomIcon {
                    Image(item.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: item.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(item.iconColor)
                }

                Text(item.displayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                if item.needsAttention {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
            }

            // Subtitle (path or URL)
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // Bottom row: status + badges
            HStack(spacing: 8) {
                statusView
                Spacer()
                badgesView
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: Theme.sidebarBackground))
                .opacity(isHovered ? 1.0 : 0.8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .onHover { isHovered = $0 }
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusView: some View {
        if item.sessionType == .browser {
            if let count = item.tabCount {
                Label("\(count) tab\(count == 1 ? "" : "s")", systemImage: "square.on.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(item.agentStatus.dotColor)
                    .frame(width: 7, height: 7)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(item.agentStatus.isActive ? .primary : .secondary)
            }
        }
    }

    private var statusText: String {
        if item.sessionType.isAgent {
            return item.agentStatus.displayText
        }
        return item.isRunning ? "Running" : "Stopped"
    }

    @ViewBuilder
    private var badgesView: some View {
        if let locationName = item.locationName {
            Text(locationName)
                .font(.caption2)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        if let intentName = item.intentName {
            Text(intentName)
                .font(.caption2)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.purple.opacity(0.12))
                .foregroundStyle(.purple)
                .clipShape(Capsule())
        }
    }

    private var borderColor: Color {
        if item.agentStatus.isActive {
            return item.agentStatus.dotColor.opacity(0.3)
        }
        return .white.opacity(0.06)
    }
}
