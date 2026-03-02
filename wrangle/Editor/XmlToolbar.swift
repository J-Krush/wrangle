import SwiftUI

/// A compact toolbar shown when editing XML/plist files, providing format,
/// insert, and validation actions — modeled on `JsonToolbar`.
struct XmlToolbar: View {
    @Binding var text: String
    var isPlist: Bool = false
    var onInsert: ((String) -> Void)?

    @State private var validationMessage: String?
    @State private var isValid: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            // XML indicator badge
            HStack(spacing: 4) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                Text(isPlist ? "Plist" : "XML")
                    .font(.caption.bold())
            }
            .foregroundColor(.secondary)

            Divider().frame(height: 16)

            // Format button
            Button {
                formatXML()
            } label: {
                Label("Format", systemImage: "text.alignleft")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Prettify XML (format with indentation)")

            Divider().frame(height: 16)

            // Insert helpers
            Menu {
                if isPlist {
                    Section("Plist") {
                        Button("Key + String") { onInsert?("<key>name</key>\n<string>value</string>") }
                        Button("Key + Integer") { onInsert?("<key>name</key>\n<integer>0</integer>") }
                        Button("Key + Boolean") { onInsert?("<key>name</key>\n<true/>") }
                        Button("Dict") { onInsert?("<dict>\n\t\n</dict>") }
                        Button("Array") { onInsert?("<array>\n\t\n</array>") }
                    }
                    Divider()
                }
                Section("XML") {
                    Button("Element") { onInsert?("<tag>\n\t\n</tag>") }
                    Button("Self-Closing") { onInsert?("<tag />") }
                    Button("Comment") { onInsert?("<!-- comment -->") }
                    Button("CDATA") { onInsert?("<![CDATA[\n\t\n]]>") }
                }
            } label: {
                Label("Insert", systemImage: "plus.circle")
                    .font(.caption)
            }
            .menuStyle(.borderlessButton)
            .help("Insert XML structure")

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
            validateXML(newValue)
        }
        .onAppear {
            validateXML(text)
        }
    }

    // MARK: - Format

    private func formatXML() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let xmlDoc = try XMLDocument(xmlString: trimmed, options: .nodePreserveAll)
            let prettyData = xmlDoc.xmlData(options: .nodePrettyPrint)
            if let pretty = String(data: prettyData, encoding: .utf8) {
                text = pretty
            }
        } catch {
            // Do nothing on invalid XML — can't format it
        }
    }

    // MARK: - Validation

    private func validateXML(_ xml: String) {
        let trimmed = xml.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isValid = true
            validationMessage = "Empty"
            return
        }
        do {
            _ = try XMLDocument(xmlString: trimmed, options: [])
            isValid = true
            validationMessage = "Valid"
        } catch {
            isValid = false
            let msg = error.localizedDescription
            validationMessage = String(msg.prefix(60))
        }
    }
}
