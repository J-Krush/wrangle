import Foundation
import SwiftUI

enum FileType: String, CaseIterable {
    case claudeMD
    case skillMD
    case agentsMD
    case systemPrompt
    case mcpConfig
    case markdown
    case json
    case yaml
    case swift
    case code
    case shell
    case config
    case plainText

    var displayName: String {
        switch self {
        case .claudeMD: "Claude Config"
        case .skillMD: "Skill Definition"
        case .agentsMD: "Agents Config"
        case .systemPrompt: "System Prompt"
        case .mcpConfig: "MCP Config"
        case .markdown: "Markdown"
        case .json: "JSON"
        case .yaml: "YAML"
        case .swift: "Swift"
        case .code: "Source Code"
        case .shell: "Shell Script"
        case .config: "Config"
        case .plainText: "Plain Text"
        }
    }

    var iconName: String {
        switch self {
        case .claudeMD: "brain.head.profile"
        case .skillMD: "wand.and.stars"
        case .agentsMD: "person.3"
        case .systemPrompt: "terminal"
        case .mcpConfig: "gearshape.2"
        case .markdown: "doc.text"
        case .json: "curlybraces"
        case .yaml: "list.bullet.indent"
        case .swift: "swift"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .shell: "apple.terminal"
        case .config: "gearshape"
        case .plainText: "doc.plaintext"
        }
    }

    var iconColor: Color {
        switch self {
        case .claudeMD: .orange
        case .skillMD: .purple
        case .agentsMD: .blue
        case .systemPrompt: .green
        case .mcpConfig: .gray
        case .markdown: .secondary
        case .json: .yellow
        case .yaml: .pink
        case .swift: .orange
        case .code: .cyan
        case .shell: .mint
        case .config: .gray
        case .plainText: .secondary
        }
    }

    private static let markdownExtensions: Set<String> = ["md", "markdown", "mdx", "mdown", "mkd"]
    private static let jsonExtensions: Set<String> = ["json", "jsonc", "json5"]
    private static let yamlExtensions: Set<String> = ["yaml", "yml"]
    private static let swiftExtensions: Set<String> = ["swift"]
    private static let shellExtensions: Set<String> = ["sh", "bash", "zsh", "fish", "bat", "cmd", "ps1", "psm1"]
    private static let configExtensions: Set<String> = [
        "toml", "ini", "cfg", "conf", "env", "properties", "plist",
        "editorconfig", "gitignore", "gitattributes", "dockerignore",
        "eslintrc", "prettierrc", "babelrc", "nvmrc",
        "xcconfig", "entitlements", "pbxproj",
    ]
    private static let codeExtensions: Set<String> = [
        "js", "jsx", "ts", "tsx", "mjs", "cjs", "mts", "cts",
        "py", "rb", "php", "pl", "pm", "lua", "r", "jl",
        "java", "kt", "kts", "go", "rs", "zig", "nim", "v", "d", "scala",
        "c", "cpp", "cc", "cxx", "cs", "h", "hpp", "m", "mm",
        "ex", "exs", "erl", "hrl", "hs", "ml", "mli", "fs", "fsi", "fsx",
        "clj", "cljs", "cljc", "dart", "cr", "groovy", "gradle",
        "html", "htm", "xml", "svg", "css", "scss", "sass", "less",
        "sql", "graphql", "gql", "prisma", "proto", "tf", "hcl",
    ]

    static func detect(from url: URL) -> FileType {
        let name = url.lastPathComponent.lowercased()
        let ext = url.pathExtension.lowercased()

        // Special AI-related files first
        if name == "claude.md" || name == ".claude.md" || name == ".claude/claude.md" {
            return .claudeMD
        }
        if name == "skill.md" { return .skillMD }
        if name == "agents.md" { return .agentsMD }
        if name == "system-prompt.md" || name == "system_prompt.md" { return .systemPrompt }
        if jsonExtensions.contains(ext) && (name.contains("mcp") || name.contains("claude")) {
            return .mcpConfig
        }

        // General file types by extension
        if markdownExtensions.contains(ext) { return .markdown }
        if jsonExtensions.contains(ext) { return .json }
        if yamlExtensions.contains(ext) { return .yaml }
        if swiftExtensions.contains(ext) { return .swift }
        if shellExtensions.contains(ext) { return .shell }
        if configExtensions.contains(ext) { return .config }
        if codeExtensions.contains(ext) { return .code }

        if ext == "txt" || ext == "text" || ext == "log" || ext == "rst" || ext == "adoc" || ext == "org" || ext == "tex" {
            return .plainText
        }

        return .plainText
    }

    static func detect(from content: String) -> FileType {
        if content.contains("<tools>") || content.contains("<instructions>") || content.contains("<system>") {
            return .systemPrompt
        }
        return .plainText
    }
}

enum FileTypeFilter: String, CaseIterable, Identifiable {
    case markdown, json, yaml, swift, shell, config, code, plainText

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .markdown: "Markdown"
        case .json: "JSON"
        case .yaml: "YAML"
        case .swift: "Swift"
        case .shell: "Shell"
        case .config: "Config"
        case .code: "Code"
        case .plainText: "Plain Text"
        }
    }

    var iconName: String {
        switch self {
        case .markdown: "doc.text"
        case .json: "curlybraces"
        case .yaml: "list.bullet.indent"
        case .swift: "swift"
        case .shell: "apple.terminal"
        case .config: "gearshape"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .plainText: "doc.plaintext"
        }
    }

    var iconColor: Color {
        switch self {
        case .markdown: .secondary
        case .json: .yellow
        case .yaml: .pink
        case .swift: .orange
        case .shell: .mint
        case .config: .gray
        case .code: .cyan
        case .plainText: .secondary
        }
    }

    var matchingFileTypes: Set<FileType> {
        switch self {
        case .markdown: [.claudeMD, .skillMD, .agentsMD, .systemPrompt, .markdown]
        case .json: [.json, .mcpConfig]
        case .yaml: [.yaml]
        case .swift: [.swift]
        case .shell: [.shell]
        case .config: [.config]
        case .code: [.code]
        case .plainText: [.plainText]
        }
    }
}

@MainActor
@Observable
class EditorDocument: Identifiable {
    let id = UUID()
    var fileURL: URL?
    var content: String
    var isDirty: Bool = false
    var isLoading: Bool = false
    var loadError: String?
    var lastSavedContent: String
    /// The security-scoped directory URL granting access to this file, if any.
    /// Excluded from observation — only used internally for security-scoped access lifecycle.
    @ObservationIgnored private var accessURL: URL?

    // Cached stats — updated via debounced `updateCachedStats()`
    var cachedTokenCount: Int = 0
    var cachedLineCount: Int = 1
    var cachedCharCount: Int = 0
    private var statsTask: Task<Void, Never>?

    var fileName: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }

    var fileType: FileType {
        if let url = fileURL {
            let urlType = FileType.detect(from: url)
            if urlType != .plainText { return urlType }
        }
        return FileType.detect(from: content)
    }

    init(fileURL: URL? = nil, content: String = "") {
        self.fileURL = fileURL
        self.content = content
        self.lastSavedContent = content
    }

    deinit {
        accessURL?.stopAccessingSecurityScopedResource()
    }

    /// Retains a security-scoped URL so this document can continue reading/writing
    /// even if the sidebar's security-scoped access is released.
    func retainAccess(from scopedURL: URL) {
        guard accessURL != scopedURL else { return }
        accessURL?.stopAccessingSecurityScopedResource()
        _ = scopedURL.startAccessingSecurityScopedResource()
        accessURL = scopedURL
    }

    func load() throws {
        guard let url = fileURL else { return }
        loadError = nil

        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Fallback: isoLatin1 maps every byte, never throws for encoding
            do {
                content = try String(contentsOf: url, encoding: .isoLatin1)
            } catch let fallbackError {
                loadError = fallbackError.localizedDescription
                throw fallbackError
            }
        }
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
        scheduleCachedStatsUpdate()
    }

    func updateCachedStats() {
        let text = content
        cachedCharCount = text.count
        cachedLineCount = text.isEmpty ? 1 : text.components(separatedBy: "\n").count
        cachedTokenCount = TokenCounter.count(text)
    }

    private func scheduleCachedStatsUpdate() {
        statsTask?.cancel()
        statsTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            updateCachedStats()
        }
    }
}
