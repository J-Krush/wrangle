import SwiftUI

struct FileNode: Identifiable, Comparable, Sendable {
    var id: URL { url }
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileNode]?

    /// Extensions recognized as text-based and openable in the editor.
    private static let openableExtensions: Set<String> = [
        // Markdown
        "md", "markdown", "mdx", "mdown", "mkd",
        // Config / data
        "json", "jsonc", "json5", "yaml", "yml", "toml", "ini", "cfg", "conf",
        "env", "properties", "plist",
        // Web
        "html", "htm", "xml", "svg", "css", "scss", "sass", "less",
        // JavaScript / TypeScript
        "js", "jsx", "ts", "tsx", "mjs", "cjs", "mts", "cts",
        // Swift / Apple
        "swift", "m", "mm", "h", "hpp", "entitlements", "pbxproj", "xcscheme",
        "xcconfig", "storyboard", "xib",
        // Systems
        "c", "cpp", "cc", "cxx", "cs", "java", "kt", "kts", "go", "rs",
        "zig", "nim", "v", "d", "scala",
        // Scripting
        "py", "rb", "php", "pl", "pm", "lua", "r", "jl", "ex", "exs",
        "erl", "hrl", "hs", "ml", "mli", "fs", "fsi", "fsx",
        "clj", "cljs", "cljc", "dart", "cr", "groovy", "gradle",
        // Shell
        "sh", "bash", "zsh", "fish", "bat", "cmd", "ps1", "psm1",
        // Data / query
        "sql", "graphql", "gql", "csv", "tsv",
        // Docs / text
        "txt", "text", "rst", "adoc", "org", "tex", "log", "rtf",
        // Dev config (dotfiles with extensions)
        "editorconfig", "gitignore", "gitattributes", "dockerignore",
        "eslintrc", "prettierrc", "babelrc", "nvmrc",
        // Other
        "vim", "el", "lock", "prisma", "proto", "tf", "hcl",
        "cmake", "makefile", "rake",
    ]

    /// File names (without meaningful extensions) that are known text files.
    private static let openableFileNames: Set<String> = [
        "makefile", "dockerfile", "containerfile", "gemfile", "rakefile",
        "podfile", "fastfile", "procfile", "vagrantfile", "brewfile",
        "license", "licence", "readme", "changelog", "contributing",
        "authors", "codeowners", "todo", "copying", "install",
        "claude.md", ".claude.md",
        // Dotfiles
        ".gitignore", ".gitattributes", ".gitmodules",
        ".editorconfig", ".dockerignore",
        ".eslintignore", ".prettierignore",
        ".swiftlint.yml", ".swiftformat",
    ]

    /// Prefixes for dotfiles that should be openable regardless of their extension variant
    /// (e.g., .env, .env.local, .env.production are all openable).
    private static let openableDotPrefixes: [String] = [
        ".env", ".eslintrc", ".prettierrc", ".babelrc",
    ]

    var isOpenable: Bool {
        if isDirectory { return false }
        let lower = name.lowercased()
        // Check exact file names first (handles dotfiles and extensionless files)
        if Self.openableFileNames.contains(lower) { return true }
        // Check dotfile prefix patterns (e.g., .env, .env.local, .env.production)
        if lower.hasPrefix(".") {
            for prefix in Self.openableDotPrefixes {
                if lower == prefix || lower.hasPrefix(prefix + ".") { return true }
            }
        }
        // Check by file extension
        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty {
            return Self.openableExtensions.contains(ext)
        }
        return false
    }

    var fileType: FileType {
        FileType.detect(from: url)
    }

    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        if !isOpenable {
            return "doc"
        }
        return fileType.iconName
    }

    var iconColor: Color {
        if isDirectory { return .gray }
        if !isOpenable { return .secondary.opacity(0.5) }
        return fileType.iconColor
    }

    static func < (lhs: FileNode, rhs: FileNode) -> Bool {
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    /// Directory names that should appear as folders but not be recursed into.
    private nonisolated static let skippedDirectories: Set<String> = [
        "node_modules", ".git", "DerivedData", ".build", "Pods",
        ".svn", ".hg", "vendor", "dist", "build", ".next",
        "__pycache__", ".tox", ".venv", "venv",
    ]

    /// Hidden (dot-prefixed) directory names that should still appear in the file tree.
    private nonisolated static let allowedHiddenDirs: Set<String> = [
        ".claude", ".cursor", ".cursorrules", ".gemini",
        ".agent", ".agents", ".github", ".vscode",
        ".planning",
    ]

    /// Hidden (dot-prefixed) file names that should still appear in the file tree.
    private nonisolated static let allowedHiddenFiles: Set<String> = [
        ".env", ".env.local", ".env.development", ".env.production", ".env.staging", ".env.test",
        ".env.example", ".env.sample",
        ".gitignore", ".gitattributes", ".gitmodules",
        ".editorconfig",
        ".eslintrc", ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yml",
        ".prettierrc", ".prettierrc.json", ".prettierrc.js", ".prettierrc.yml",
        ".prettierignore", ".eslintignore",
        ".babelrc", ".babelrc.json",
        ".nvmrc", ".node-version", ".ruby-version", ".python-version", ".tool-versions",
        ".dockerignore",
        ".claude.md", ".cursorrules",
        ".swiftlint.yml", ".swiftformat",
    ]

    /// Recursively builds a file tree rooted at `url`, descending up to `depth` levels.
    /// When `showAllHidden` is true, all dotfiles are shown except those in `skippedDirectories`.
    nonisolated static func buildTree(at url: URL, depth: Int = 20, showAllHidden: Bool = false) -> [FileNode] {
        guard depth > 0 else { return [] }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return []
        }

        return contents.compactMap { childURL in
            let name = childURL.lastPathComponent
            let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

            // Filter hidden files/dirs
            if name.hasPrefix(".") && !showAllHidden {
                let allowed = isDir ? allowedHiddenDirs.contains(name) : allowedHiddenFiles.contains(name)
                if !allowed { return nil }
            }

            var children: [FileNode]? = nil
            if isDir {
                if skippedDirectories.contains(name) {
                    children = nil
                } else {
                    children = buildTree(at: childURL, depth: depth - 1, showAllHidden: showAllHidden)
                }
            }
            return FileNode(
                url: childURL,
                name: name,
                isDirectory: isDir,
                children: children
            )
        }.sorted()
    }

    /// Returns a filtered copy of this node, or nil if it doesn't match the filter.
    func filtered(by filter: String) -> FileNode? {
        if filter.isEmpty { return self }
        let nameMatches = name.localizedCaseInsensitiveContains(filter)
        if !isDirectory {
            return nameMatches ? self : nil
        }
        let filteredChildren = children?.compactMap { $0.filtered(by: filter) }
        if nameMatches || !(filteredChildren?.isEmpty ?? true) {
            var node = self
            node.children = filteredChildren
            return node
        }
        return nil
    }

    /// Returns a filtered copy matching both text filter and file type filters.
    func filtered(by filter: String, fileTypes: Set<FileTypeFilter>) -> FileNode? {
        if filter.isEmpty && fileTypes.isEmpty { return self }

        // For files: must match text AND type (when each is active)
        if !isDirectory {
            let textMatch = filter.isEmpty || name.localizedCaseInsensitiveContains(filter)
            let typeMatch = fileTypes.isEmpty || fileTypes.contains(where: { $0.matchingFileTypes.contains(fileType) || $0.matchesFileName(name) })
            return (textMatch && typeMatch) ? self : nil
        }

        // For directories: show if any child matches; also show if directory name matches text
        // (but only when no type filters are active — type filters only match files)
        let filteredChildren = children?.compactMap { $0.filtered(by: filter, fileTypes: fileTypes) }
        let hasMatchingChildren = !(filteredChildren?.isEmpty ?? true)
        let dirNameMatchesText = !filter.isEmpty && fileTypes.isEmpty && name.localizedCaseInsensitiveContains(filter)

        if hasMatchingChildren || dirNameMatchesText {
            var node = self
            node.children = filteredChildren
            return node
        }
        return nil
    }
}

// MARK: - FileTreeNodeView

struct FileTreeNodeView: View {
    let node: FileNode
    let bookmarkID: String
    let onSelect: (URL) -> Void
    var onDoubleClick: ((URL) -> Void)? = nil
    @Environment(AppState.self) private var appState
    @State private var isExpanded = false

    private var isSelected: Bool {
        if node.isDirectory {
            return appState.selectedFileTreeURL == node.url
        } else {
            return appState.activeDocument?.fileURL == node.url
        }
    }

    var body: some View {
        if node.isDirectory {
            directoryView
        } else if node.isOpenable {
            openableFileView
        } else {
            unopenableFileView
        }
    }

    // MARK: - Directory View

    private var directoryView: some View {
        // M-2: Use Button inside DisclosureGroup label instead of onTapGesture
        DisclosureGroup(isExpanded: $isExpanded) {
            if let children = node.children {
                ForEach(children) { child in
                    FileTreeNodeView(node: child, bookmarkID: bookmarkID, onSelect: onSelect, onDoubleClick: onDoubleClick)
                }
            }
        } label: {
            Button {
                appState.selectedFileTreeURL = node.url
                isExpanded.toggle()
            } label: {
                nodeLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .dropDestination(for: URL.self) { urls, _ in
                copyFiles(urls, to: node.url)
            } isTargeted: { isTargeted in
                if isTargeted { isExpanded = true }
            }
        }
        .id("\(bookmarkID)|\(node.url)")
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
        .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isSelected))
        .onChange(of: appState.revealFileURL, initial: true) { _, revealURL in
            guard let revealURL else { return }
            let revealPath = revealURL.path(percentEncoded: false)
            let dirPath = node.url.path(percentEncoded: false)
            // Expand if this directory is an ancestor of the reveal target
            if revealPath.hasPrefix(dirPath + "/") {
                isExpanded = true
            }
        }
    }

    // MARK: - Openable File View

    private var openableFileView: some View {
        Button {
            print("[FileTree] Clicked file: \(node.name) at \(node.url.path)")
            appState.selectedFileTreeURL = node.url
            onSelect(node.url)
        } label: {
            nodeLabel
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id("\(bookmarkID)|\(node.url)")
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
        .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isSelected))
        .onChange(of: appState.revealFileURL, initial: true) { _, revealURL in
            guard let revealURL else { return }
            if node.url == revealURL {
                appState.revealFileURL = nil
            }
        }
    }

    // MARK: - Unopenable File View

    private var unopenableFileView: some View {
        nodeLabel
            .foregroundStyle(.secondary)
            .opacity(0.4)
            .id("\(bookmarkID)|\(node.url)")
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
            .listRowBackground(Color.clear)
            .help("This file type cannot be opened in the editor")
    }

    // MARK: - Node Label

    private var nodeLabel: some View {
        Label {
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            Image(systemName: node.icon)
                .foregroundStyle(node.iconColor)
        }
    }

    // MARK: - Actions

    private func copyFiles(_ urls: [URL], to targetDir: URL) -> Bool {
        var success = false
        for url in urls {
            let destination = targetDir.appendingPathComponent(url.lastPathComponent)
            if destination == url { continue }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    let stem = destination.deletingPathExtension().lastPathComponent
                    let ext = destination.pathExtension
                    let uniqueName = ext.isEmpty ? "\(stem) copy" : "\(stem) copy.\(ext)"
                    let uniqueDest = targetDir.appendingPathComponent(uniqueName)
                    try FileManager.default.copyItem(at: url, to: uniqueDest)
                    onSelect(uniqueDest)
                } else {
                    try FileManager.default.copyItem(at: url, to: destination)
                    onSelect(destination)
                }
                success = true
            } catch {
                // Copy failed
            }
        }
        return success
    }
}
