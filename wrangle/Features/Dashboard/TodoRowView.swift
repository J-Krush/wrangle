//
//  TodoRowView.swift
//  Wrangle
//

import SwiftUI
import SwiftData

struct TodoRowView: View {
    let todo: TodoItem
    @Environment(\.modelContext) private var modelContext

    // Editing state
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isEditFieldFocused: Bool

    // Delayed completion state
    @State private var isPendingCompletion = false
    @State private var isHovered = false
    @State private var completionTask: Task<Void, Never>?

    private var showAsCompleted: Bool {
        todo.isCompleted || isPendingCompletion
    }

    var body: some View {
        HStack(spacing: 10) {
            checkButton
            titleContent
            Spacer()
            deleteButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .onHover { hovering in
            isHovered = hovering
            if isPendingCompletion {
                if hovering {
                    cancelCompletionTimer()
                } else {
                    startCompletionTimer()
                }
            }
        }
        .onDisappear {
            completionTask?.cancel()
        }
    }

    // MARK: - Subviews

    private var checkButton: some View {
        Button {
            if isPendingCompletion {
                // Uncheck during grace period
                isPendingCompletion = false
                cancelCompletionTimer()
            } else if todo.isCompleted {
                // Uncheck a completed todo
                todo.isCompleted = false
                todo.dateCompleted = nil
                try? modelContext.save()
            } else {
                // Check an incomplete todo — enter pending state
                isPendingCompletion = true
                if !isHovered {
                    startCompletionTimer()
                }
            }
        } label: {
            Image(systemName: showAsCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(showAsCompleted ? .green : .secondary)
                .font(.body)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var titleContent: some View {
        if isEditing {
            TextField("", text: $editText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isEditFieldFocused)
                .onSubmit { commitEdit() }
                .onExitCommand { cancelEdit() }
                .onChange(of: isEditFieldFocused) { _, focused in
                    if !focused { commitEdit() }
                }
        } else {
            Text(todo.title)
                .font(.body)
                .foregroundStyle(showAsCompleted ? .tertiary : .primary)
                .strikethrough(showAsCompleted)
                .lineLimit(2)
                .onTapGesture(count: 2) {
                    beginEdit()
                }
        }
    }

    private var deleteButton: some View {
        Button {
            modelContext.delete(todo)
            try? modelContext.save()
        } label: {
            Image(systemName: "xmark")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .opacity(0.5)
    }

    // MARK: - Editing

    private func beginEdit() {
        // Cancel pending completion if active
        if isPendingCompletion {
            isPendingCompletion = false
            cancelCompletionTimer()
        }
        editText = todo.title
        isEditing = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            isEditFieldFocused = true
        }
    }

    private func commitEdit() {
        guard isEditing else { return }
        isEditing = false
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return } // revert if empty
        todo.title = trimmed
        try? modelContext.save()
    }

    private func cancelEdit() {
        isEditing = false
    }

    // MARK: - Delayed Completion

    private func startCompletionTimer() {
        completionTask?.cancel()
        completionTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                isPendingCompletion = false
                todo.isCompleted = true
                todo.dateCompleted = .now
                try? modelContext.save()
            }
        }
    }

    private func cancelCompletionTimer() {
        completionTask?.cancel()
        completionTask = nil
    }
}
