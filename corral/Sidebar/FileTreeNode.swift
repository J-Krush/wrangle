import SwiftUI

struct FileNode: Identifiable, Comparable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileNode]?

    var fileType: FileType {
        FileType.detect(from: url)
    }

    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        return fileType.iconName
    }

    var iconColor: Color {
        if isDirectory { return .blue }
        return fileType.iconColor
    }

    static func < (lhs: FileNode, rhs: FileNode) -> Bool {
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

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
                children = buildTree(at: childURL, depth: depth - 1)
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
    @Environment(AppState.self) private var appState
    @State private var isExpanded = false
    @State private var isHovering = false

    private var isStarred: Bool {
        appState.starredFileURLs.contains(node.url.absoluteString)
    }

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let children = node.children {
                    ForEach(children) { child in
                        FileTreeNodeView(node: child, onSelect: onSelect)
                    }
                }
            } label: {
                nodeLabel
            }
            .onHover { isHovering = $0 }
        } else {
            Button {
                onSelect(node.url)
            } label: {
                nodeLabel
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
        }
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
                    .onTapGesture {
                        toggleStar()
                    }
            }
        }
    }

    private func toggleStar() {
        let urlString = node.url.absoluteString
        if appState.starredFileURLs.contains(urlString) {
            appState.starredFileURLs.remove(urlString)
        } else {
            appState.starredFileURLs.insert(urlString)
        }
    }
}
