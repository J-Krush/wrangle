//
//  SessionContextParser.swift
//  wrangle
//

import Foundation

/// Namespace for static parsing methods. All methods are sync and designed to run on `Task.detached`.
nonisolated enum SessionContextParser {
    private static let fm = FileManager.default
    private static let home = FileManager.default.homeDirectoryForCurrentUser

    // MARK: - Context Files

    static func parseContextFiles(in directory: URL, isClaude: Bool, isGemini: Bool) -> [ContextFile] {
        var results: [ContextFile] = []
        var seen = Set<String>()

        func add(_ relativePath: String, from base: URL, type: FileType) {
            let url = base.appendingPathComponent(relativePath)
            guard fm.fileExists(atPath: url.path), !seen.contains(url.path) else { return }
            seen.insert(url.path)
            results.append(ContextFile(name: url.lastPathComponent, url: url, fileType: type))
        }

        if isClaude {
            add("CLAUDE.md", from: directory, type: .claudeMD)
            add(".claude.md", from: directory, type: .claudeMD)
            add(".claude/claude.md", from: directory, type: .claudeMD)
            add("CLAUDE.md", from: home, type: .claudeMD)
        }

        if isGemini {
            add("GEMINI.md", from: directory, type: .markdown)
            add(".gemini/GEMINI.md", from: directory, type: .markdown)
            add("GEMINI.md", from: home, type: .markdown)
        }

        // Common files
        add("AGENTS.md", from: directory, type: .agentsMD)
        add("SKILL.md", from: directory, type: .skillMD)

        return results
    }

    // MARK: - Skills & Extensions

    static func parseSkills(in directory: URL, isClaude: Bool, isGemini: Bool) -> [SkillEntry] {
        var results: [SkillEntry] = []

        if isClaude {
            results.append(contentsOf: parseClaudeSkills(in: directory))
        }

        if isGemini {
            results.append(contentsOf: parseGeminiExtensions(in: directory))
        }

        return results
    }

    private static func parseClaudeSkills(in directory: URL) -> [SkillEntry] {
        var results: [SkillEntry] = []

        // skills-lock.json in project root
        let lockFile = directory.appendingPathComponent("skills-lock.json")
        if let data = try? Data(contentsOf: lockFile),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let skills = json["skills"] as? [String: Any] {
            for (name, value) in skills {
                var source = "project"
                var sourceType = "locked"
                if let info = value as? [String: Any] {
                    source = info["source"] as? String ?? source
                    sourceType = info["sourceType"] as? String ?? sourceType
                }
                results.append(SkillEntry(name: name, source: source, sourceType: sourceType))
            }
        }

        // ~/.claude/skills/ — each subdirectory is a user skill
        let userSkillsDir = home.appendingPathComponent(".claude/skills")
        if let entries = try? fm.contentsOfDirectory(atPath: userSkillsDir.path) {
            for entry in entries {
                let entryPath = userSkillsDir.appendingPathComponent(entry)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: entryPath.path, isDirectory: &isDir), isDir.boolValue {
                    results.append(SkillEntry(name: entry, source: "~/.claude/skills/", sourceType: "user"))
                }
            }
        }

        return results
    }

    private static func parseGeminiExtensions(in directory: URL) -> [SkillEntry] {
        var results: [SkillEntry] = []

        func scanExtensionsDir(_ dir: URL, source: String) {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir.path) else { return }
            for entry in entries {
                let extFile = dir.appendingPathComponent(entry).appendingPathComponent("gemini-extension.json")
                guard let data = try? Data(contentsOf: extFile),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                let name = json["name"] as? String ?? entry
                results.append(SkillEntry(name: name, source: source, sourceType: "extension"))
            }
        }

        // Global extensions
        scanExtensionsDir(home.appendingPathComponent(".gemini/extensions"), source: "~/.gemini/extensions/")

        // Project-level extensions
        scanExtensionsDir(directory.appendingPathComponent(".gemini/extensions"), source: ".gemini/extensions/")

        return results
    }

    // MARK: - MCP Servers

    static func parseMCPServers(in directory: URL, isClaude: Bool, isGemini: Bool) -> [MCPServer] {
        var results: [MCPServer] = []
        var seen = Set<String>()

        func addServers(from url: URL) {
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let servers = json["mcpServers"] as? [String: Any] else { return }
            for (name, value) in servers {
                guard !seen.contains(name) else { continue }
                seen.insert(name)
                let command = (value as? [String: Any])?["command"] as? String
                results.append(MCPServer(name: name, command: command, status: .configured))
            }
        }

        if isClaude {
            addServers(from: home.appendingPathComponent(".claude.json"))
            addServers(from: home.appendingPathComponent(".claude/settings.json"))
            addServers(from: directory.appendingPathComponent(".mcp.json"))
            addServers(from: directory.appendingPathComponent(".claude/settings.json"))
        }

        if isGemini {
            addServers(from: home.appendingPathComponent(".gemini/settings.json"))
            addServers(from: directory.appendingPathComponent(".gemini/settings.json"))

            // Gemini extensions can also define MCP servers
            let extDir = home.appendingPathComponent(".gemini/extensions")
            if let entries = try? fm.contentsOfDirectory(atPath: extDir.path) {
                for entry in entries {
                    addServers(from: extDir.appendingPathComponent(entry).appendingPathComponent("gemini-extension.json"))
                }
            }
        }

        return results
    }
}
