import SwiftUI
import SwiftData

struct IntentListView: View {
    let projectID: String
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var intents: [Intent]
    @State private var isCreating = false
    @State private var newIntentName = ""
    @State private var renamingIntent: Intent?
    @State private var renameText = ""

    init(projectID: String) {
        self.projectID = projectID
        _intents = Query(
            filter: #Predicate<Intent> { intent in
                intent.projectID == projectID
            },
            sort: \Intent.displayOrder
        )
    }

    var body: some View {
        ForEach(intents) { intent in
            intentRow(intent)
        }

        if isCreating {
            newIntentField
        }

        Button {
            isCreating = true
            newIntentName = ""
        } label: {
            Label("New Intent", systemImage: "plus")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .alert("Rename Intent", isPresented: Binding(
            get: { renamingIntent != nil },
            set: { if !$0 { renamingIntent = nil } }
        )) {
            TextField("Intent name", text: $renameText)
            Button("Rename") {
                guard let intent = renamingIntent else { return }
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { intent.name = trimmed }
                try? modelContext.save()
                renamingIntent = nil
            }
            Button("Cancel", role: .cancel) { renamingIntent = nil }
        }
    }

    // MARK: - Subviews

    private func intentRow(_ intent: Intent) -> some View {
        let isActive = appState.activeIntentID == intent.id
        return Button {
            if isActive {
                appState.activeIntentID = nil
            } else {
                appState.activeIntentID = intent.id
            }
        } label: {
            HStack(spacing: 6) {
                statusPip(intent.status)
                Text(intent.name)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
                if isActive {
                    Text("active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isActive ? Color.accentColor.opacity(0.1) : Color.clear
        )
        .contextMenu {
            Button("Rename...") {
                renameText = intent.name
                renamingIntent = intent
            }
            Divider()
            ForEach(Intent.Status.allCases, id: \.self) { status in
                if intent.status != status {
                    Button("Mark as \(status.label)") {
                        intent.status = status
                        try? modelContext.save()
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                if appState.activeIntentID == intent.id {
                    appState.activeIntentID = nil
                }
                modelContext.delete(intent)
                try? modelContext.save()
            }
        }
    }

    @ViewBuilder
    private func statusPip(_ status: Intent.Status) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 7, height: 7)
    }

    private func statusColor(_ status: Intent.Status) -> Color {
        switch status {
        case .active: .green
        case .paused: .yellow
        case .archived: .gray
        }
    }

    private var newIntentField: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 7, height: 7)
            TextField("Intent name", text: $newIntentName)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit { commitNewIntent() }
            Button {
                isCreating = false
                newIntentName = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    private func commitNewIntent() {
        let name = newIntentName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            isCreating = false
            return
        }
        let maxOrder = intents.map(\.displayOrder).max() ?? -1
        let intent = Intent(name: name, projectID: projectID, displayOrder: maxOrder + 1)
        modelContext.insert(intent)
        try? modelContext.save()
        appState.activeIntentID = intent.id
        isCreating = false
        newIntentName = ""
    }
}
