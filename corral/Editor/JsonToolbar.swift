import SwiftUI

/// A compact toolbar shown when editing JSON files, providing format, minify,
/// insert, and validation actions.
struct JsonToolbar: View {
    @Binding var text: String
    var onInsert: ((String) -> Void)?

    @State private var validationMessage: String?
    @State private var isValid: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            // JSON indicator badge
            HStack(spacing: 4) {
                Image(systemName: "curlybraces")
                    .font(.caption)
                Text("JSON")
                    .font(.caption.bold())
            }
            .foregroundColor(.secondary)

            Divider().frame(height: 16)

            // Format button
            Button {
                if let pretty = JsonSyntaxHighlighter.prettify(text) {
                    text = pretty
                }
            } label: {
                Label("Format", systemImage: "text.alignleft")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Prettify JSON (format with indentation)")

            // Minify button
            Button {
                if let mini = JsonSyntaxHighlighter.minify(text) {
                    text = mini
                }
            } label: {
                Label("Minify", systemImage: "arrow.down.right.and.arrow.up.left")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Minify JSON (remove whitespace)")

            Divider().frame(height: 16)

            // Insert helpers
            Menu {
                Button("Empty Object { }") { onInsert?("{}") }
                Button("Empty Array [ ]") { onInsert?("[]") }
                Button("String Property") { onInsert?("\"key\": \"value\"") }
                Button("Number Property") { onInsert?("\"key\": 0") }
                Button("Boolean Property") { onInsert?("\"key\": true") }
                Button("Null Property") { onInsert?("\"key\": null") }
                Divider()
                Button("Nested Object") { onInsert?("\"key\": {\n  \n}") }
                Button("Nested Array") { onInsert?("\"key\": [\n  \n]") }
            } label: {
                Label("Insert", systemImage: "plus.circle")
                    .font(.caption)
            }
            .menuStyle(.borderlessButton)
            .help("Insert JSON structure")

            Divider().frame(height: 16)

            // Validation status
            HStack(spacing: 4) {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(isValid ? .green : .red)
                Text(validationMessage ?? (isValid ? "Valid" : "Invalid"))
                    .font(.caption2)
                    .foregroundColor(isValid ? .green : .red)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onChange(of: text) { _, newValue in
            validateJSON(newValue)
        }
        .onAppear {
            validateJSON(text)
        }
    }

    // MARK: - Validation

    private func validateJSON(_ json: String) {
        guard !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isValid = true
            validationMessage = "Empty"
            return
        }
        guard let data = json.data(using: .utf8) else {
            isValid = false
            validationMessage = "Invalid encoding"
            return
        }
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            isValid = true
            validationMessage = "Valid"
        } catch {
            isValid = false
            let msg = error.localizedDescription
            validationMessage = String(msg.prefix(50))
        }
    }
}
