import Foundation
import SwiftUI

enum FileType: String, CaseIterable {
    case claudeMD
    case skillMD
    case agentsMD
    case systemPrompt
    case mcpConfig
    case regular

    var displayName: String {
        switch self {
        case .claudeMD: "Claude Config"
        case .skillMD: "Skill Definition"
        case .agentsMD: "Agents Config"
        case .systemPrompt: "System Prompt"
        case .mcpConfig: "MCP Config"
        case .regular: "Markdown"
        }
    }

    var iconName: String {
        switch self {
        case .claudeMD: "brain.head.profile"
        case .skillMD: "wand.and.stars"
        case .agentsMD: "person.3"
        case .systemPrompt: "terminal"
        case .mcpConfig: "gearshape.2"
        case .regular: "doc.text"
        }
    }

    var iconColor: Color {
        switch self {
        case .claudeMD: .orange
        case .skillMD: .purple
        case .agentsMD: .blue
        case .systemPrompt: .green
        case .mcpConfig: .gray
        case .regular: .secondary
        }
    }

    static func detect(from url: URL) -> FileType {
        let name = url.lastPathComponent.lowercased()
        if name == "claude.md" || name == ".claude.md" || name == ".claude/claude.md" {
            return .claudeMD
        }
        if name == "skill.md" { return .skillMD }
        if name == "agents.md" { return .agentsMD }
        if name == "system-prompt.md" || name == "system_prompt.md" { return .systemPrompt }
        if name.hasSuffix(".json") && (name.contains("mcp") || name.contains("claude")) {
            return .mcpConfig
        }
        return .regular
    }

    static func detect(from content: String) -> FileType {
        if content.contains("<tools>") || content.contains("<instructions>") || content.contains("<system>") {
            return .systemPrompt
        }
        return .regular
    }
}

@Observable
class EditorDocument: Identifiable {
    let id = UUID()
    var fileURL: URL?
    var content: String
    var isDirty: Bool = false
    var lastSavedContent: String

    var fileName: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }

    var fileType: FileType {
        if let url = fileURL {
            let urlType = FileType.detect(from: url)
            if urlType != .regular { return urlType }
        }
        return FileType.detect(from: content)
    }

    init(fileURL: URL? = nil, content: String = "") {
        self.fileURL = fileURL
        self.content = content
        self.lastSavedContent = content
    }

    func load() throws {
        guard let url = fileURL else { return }
        content = try String(contentsOf: url, encoding: .utf8)
        lastSavedContent = content
        isDirty = false
    }

    func save() throws {
        guard let url = fileURL else {
            throw CocoaError(.fileWriteNoPermission)
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
        lastSavedContent = content
        isDirty = false
    }

    func saveAs(to url: URL) throws {
        fileURL = url
        try save()
    }

    func markDirty() {
        isDirty = content != lastSavedContent
    }
}
