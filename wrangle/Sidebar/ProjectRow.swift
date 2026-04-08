import SwiftUI
import SwiftData

struct ProjectRow: View {
    let project: Project
    let intentCount: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: project.colorHex) ?? .blue)
                .frame(width: 10, height: 10)

            Text(project.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            if intentCount > 0 {
                Text("\(intentCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
