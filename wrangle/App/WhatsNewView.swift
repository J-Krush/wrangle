import SwiftUI

struct WhatsNewView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        let manager = coordinator.whatsNewManager

        if manager.shouldShowModal {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)

                    Text("What's New")
                        .font(.title2)
                        .fontWeight(.semibold)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(manager.visibleEntries, id: \.version) { entry in
                                WhatsNewEntryView(entry: entry)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 300)

                    Button("Continue") {
                        manager.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .frame(width: 440)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 20)
            }
        }
    }
}

private struct WhatsNewEntryView: View {
    let entry: ChangelogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("v\(entry.version)")
                    .font(.headline)
                Spacer()
                Text(entry.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(entry.sections, id: \.category) { section in
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(colorForCategory(section.category))

                    ForEach(section.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\u{2022}")
                            Text(item)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let cta = entry.cta {
                Link(cta.label, destination: cta.url)
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .padding(.top, 4)
            }
        }
    }

    private func colorForCategory(_ category: ChangeCategory) -> Color {
        switch category {
        case .new: .purple
        case .improved: .blue
        case .fixed: .green
        }
    }
}
