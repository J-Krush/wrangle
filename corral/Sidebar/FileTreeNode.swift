import SwiftUI

struct FileNode: Identifiable, Comparable {
    let id = UUID()
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
    ]

    var isOpenable: Bool {
        if isDirectory { return false }
        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty {
            return Self.openableExtensions.contains(ext)
        }
        // Extensionless files: check by name
        return Self.openableFileNames.contains(name.lowercased())
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
        if isDirectory { return .blue }
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
    private static let skippedDirectories: Set<String> = [
        "node_modules", ".git", "DerivedData", ".build", "Pods",
        ".svn", ".hg", "vendor", "dist", "build", ".next",
        "__pycache__", ".tox", ".venv", "venv",
    ]

    /// Recursively builds a file tree rooted at `url`, descending up to `depth` levels.
    static func buildTree(at url: URL, depth: Int = 20) -> [FileNode] {
        guard depth > 0 else { return [] }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { childURL in
            let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            var children: [FileNode]? = nil
            if isDir {
                if skippedDirectories.contains(childURL.lastPathComponent) {
                    children = nil
                } else {
                    children = buildTree(at: childURL, depth: depth - 1)
                }
            }
            return FileNode(
                url: childURL,
                name: childURL.lastPathComponent,
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
}

// MARK: - FileTreeNodeView

struct FileTreeNodeView: View {
    let node: FileNode
    let onSelect: (URL) -> Void
    var onDoubleClick: ((URL) -> Void)? = nil
    @Environment(AppState.self) private var appState
    @State private var isExpanded = false
    @State private var isHovering = false
    @State private var lastClickTime: Date = .distantPast
    @State private var lastClickedURL: URL?

    private var isStarred: Bool {
        appState.starredFileURLs.contains(node.url.absoluteString)
    }

    private var isSelected: Bool {
        appState.selectedFileTreeURL == node.url
    }

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let children = node.children {
                    ForEach(children) { child in
                        FileTreeNodeView(node: child, onSelect: onSelect, onDoubleClick: onDoubleClick)
                    }
                }
            } label: {
                styledNodeLabel
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isExpanded.toggle()
                        appState.selectedFileTreeURL = node.url
                    }
                    .dropDestination(for: URL.self) { urls, _ in
                        copyFiles(urls, to: node.url)
                    } isTargeted: { isTargeted in
                        if isTargeted { isExpanded = true }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isSelected))
            .onHover { isHovering = $0 }
        } else if node.isOpenable {
            Button {
                handleFileClick()
            } label: {
                styledNodeLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Theme.sidebarSelectionBackground(isSelected: isSelected))
            .onHover { isHovering = $0 }
        } else {
            nodeLabel
                .foregroundStyle(.secondary)
                .opacity(0.4)
                .listRowBackground(Color.clear)
                .help("This file type cannot be opened in the editor")
        }
    }

    private var styledNodeLabel: some View {
        nodeLabel
    }

    private var nodeLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: node.icon)
                .foregroundStyle(node.iconColor)
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if isHovering || isStarred {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundStyle(isStarred ? .yellow : .secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleStar()
                    }
            }
        }
    }

    private func handleFileClick() {
        let now = Date()
        let isDoubleClick = lastClickedURL == node.url
            && now.timeIntervalSince(lastClickTime) < 0.3

        appState.selectedFileTreeURL = node.url

        if isDoubleClick {
            if let onDoubleClick {
                onDoubleClick(node.url)
            } else {
                onSelect(node.url)
            }
        } else {
            onSelect(node.url)
        }

        lastClickTime = now
        lastClickedURL = node.url
    }

    private func toggleStar() {
        let urlString = node.url.absoluteString
        if appState.starredFileURLs.contains(urlString) {
            appState.starredFileURLs.remove(urlString)
        } else {
            appState.starredFileURLs.insert(urlString)
        }
    }

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
