import Testing
import Foundation
@testable import Wrangle

@MainActor
@Suite("FileType Detection")
struct FileTypeTests {

    // MARK: - AI-Specific Files

    @Test("AI-specific filenames detected correctly", arguments: [
        ("claude.md", FileType.claudeMD),
        (".claude.md", FileType.claudeMD),
        ("SKILL.md", FileType.skillMD),
        ("skill.md", FileType.skillMD),
        ("AGENTS.md", FileType.agentsMD),
        ("agents.md", FileType.agentsMD),
        ("system-prompt.md", FileType.systemPrompt),
        ("system_prompt.md", FileType.systemPrompt),
    ] as [(String, FileType)])
    func aiSpecificFiles(filename: String, expected: FileType) {
        let url = URL(fileURLWithPath: "/tmp/\(filename)")
        #expect(FileType.detect(from: url) == expected)
    }

    // MARK: - MCP Config

    @Test("MCP config files detected")
    func mcpConfig() {
        let url = URL(fileURLWithPath: "/tmp/mcp-config.json")
        #expect(FileType.detect(from: url) == .mcpConfig)

        let claudeJSON = URL(fileURLWithPath: "/tmp/claude-settings.json")
        #expect(FileType.detect(from: claudeJSON) == .mcpConfig)
    }

    // MARK: - Extension-Based Detection

    @Test("Extension-based detection", arguments: [
        ("file.md", FileType.markdown),
        ("file.markdown", FileType.markdown),
        ("file.mdx", FileType.markdown),
        ("file.json", FileType.json),
        ("file.jsonc", FileType.json),
        ("file.yaml", FileType.yaml),
        ("file.yml", FileType.yaml),
        ("file.swift", FileType.swift),
        ("file.sh", FileType.shell),
        ("file.bash", FileType.shell),
        ("file.zsh", FileType.shell),
        ("file.toml", FileType.config),
        ("file.plist", FileType.config),
        ("file.js", FileType.code),
        ("file.ts", FileType.code),
        ("file.py", FileType.code),
        ("file.rs", FileType.code),
        ("file.go", FileType.code),
        ("file.html", FileType.code),
        ("file.css", FileType.code),
        ("file.txt", FileType.plainText),
        ("file.log", FileType.plainText),
    ] as [(String, FileType)])
    func extensionDetection(filename: String, expected: FileType) {
        let url = URL(fileURLWithPath: "/tmp/\(filename)")
        #expect(FileType.detect(from: url) == expected)
    }

    @Test("Unknown extension falls back to plainText")
    func unknownExtension() {
        let url = URL(fileURLWithPath: "/tmp/file.xyz")
        #expect(FileType.detect(from: url) == .plainText)
    }

    // MARK: - Content-Based Detection

    @Test("Content with XML tags detected as systemPrompt", arguments: [
        "<tools>some tools</tools>",
        "<instructions>do something</instructions>",
        "<system>you are helpful</system>",
    ])
    func contentDetection(content: String) {
        #expect(FileType.detect(from: content) == .systemPrompt)
    }

    @Test("Plain content falls back to plainText")
    func plainContent() {
        #expect(FileType.detect(from: "just some regular text") == .plainText)
    }

    // MARK: - Priority

    @Test("AI files take priority over generic markdown extension")
    func aiPriorityOverMarkdown() {
        let claudeURL = URL(fileURLWithPath: "/tmp/claude.md")
        let result = FileType.detect(from: claudeURL)
        #expect(result == .claudeMD)
        #expect(result != .markdown)
    }
}
