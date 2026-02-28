//
//  SessionContextBar.swift
//  wrangle
//

import SwiftUI

struct SessionContextBar: View {
    let session: TerminalSession
    @Environment(AppState.self) private var appState
    @State private var showSkillsPopover = false
    @State private var showMCPPopover = false
    @State private var copiedSkillId: UUID?
    @State private var copiedMCPId: UUID?

    var body: some View {
        if let context = session.sessionContext {
            contextContent(context)
        }
    }

    @ViewBuilder
    private func contextContent(_ context: SessionContext) -> some View {
        let hasContent = !context.contextFiles.isEmpty || !context.skills.isEmpty || !context.mcpServers.isEmpty

        if hasContent || context.isLoading {
            HStack(spacing: 8) {
                Text("Context & Tools")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)

                Divider().frame(height: 12)

                // Context files
                if !context.contextFiles.isEmpty {
                    contextFilePills(context.contextFiles)
                }

                if !context.contextFiles.isEmpty && (!context.skills.isEmpty || !context.mcpServers.isEmpty) {
                    Divider().frame(height: 12)
                }

                // Skills summary
                if !context.skills.isEmpty {
                    skillsPill(context.skills)
                }

                // MCP servers summary
                if !context.mcpServers.isEmpty {
                    mcpPill(context.mcpServers)
                }

                Spacer()

                // Refresh button
                Button {
                    session.refreshSessionContext()
                } label: {
                    if context.isLoading {
                        ProgressView()
                            .controlSize(.mini)
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .help("Refresh session context")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: Theme.chromeBackground))
            Divider()
        }
    }

    // MARK: - Context File Pills

    private func contextFilePills(_ files: [ContextFile]) -> some View {
        let maxVisible = 4
        let visible = Array(files.prefix(maxVisible))
        let overflow = files.count - maxVisible

        return HStack(spacing: 4) {
            ForEach(visible) { file in
                Button {
                    appState.openFile(url: file.url)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: file.fileType.iconName)
                            .font(.system(size: 8))
                            .foregroundStyle(file.fileType.iconColor)
                        Text(file.name)
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(file.fileType.iconColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help(file.url.path(percentEncoded: false))
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Skills Popover

    private func skillsPill(_ skills: [SkillEntry]) -> some View {
        Button {
            showSkillsPopover.toggle()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 8))
                    .foregroundStyle(.purple)
                Text("\(skills.count) skill\(skills.count == 1 ? "" : "s")")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showSkillsPopover, arrowEdge: .bottom) {
            skillsPopoverContent(skills)
        }
    }

    private func skillsPopoverContent(_ skills: [SkillEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Skills")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(skills) { skill in
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(skill.name, forType: .string)
                    copiedSkillId = skill.id
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        if copiedSkillId == skill.id {
                            copiedSkillId = nil
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 10))
                            .foregroundStyle(.purple)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(skill.name)
                                .font(.system(size: 11))
                            Text("\(skill.source) · \(skill.sourceType)")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: copiedSkillId == skill.id ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9))
                            .foregroundStyle(copiedSkillId == skill.id ? Color.green : Color.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Copy skill name")
            }
        }
        .padding(10)
        .frame(minWidth: 200)
    }

    // MARK: - MCP Popover

    private func mcpPill(_ servers: [MCPServer]) -> some View {
        Button {
            showMCPPopover.toggle()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 8))
                    .foregroundStyle(.gray)
                Text("\(servers.count) MCP")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMCPPopover, arrowEdge: .bottom) {
            mcpPopoverContent(servers)
        }
    }

    private func mcpPopoverContent(_ servers: [MCPServer]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MCP Servers")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(servers) { server in
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(server.name, forType: .string)
                    copiedMCPId = server.id
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        if copiedMCPId == server.id {
                            copiedMCPId = nil
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(server.status == .configured ? .green : .gray)
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(server.name)
                                .font(.system(size: 11))
                            if let command = server.command {
                                Text(command)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Image(systemName: copiedMCPId == server.id ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9))
                            .foregroundStyle(copiedMCPId == server.id ? Color.green : Color.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Copy server name")
            }
        }
        .padding(10)
        .frame(minWidth: 200)
    }
}
