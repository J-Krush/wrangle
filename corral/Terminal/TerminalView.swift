//
//  TerminalView.swift
//  corral
//
//  Created by John Kreisher on 2/21/26.
//

import SwiftUI

struct TerminalView: View {
    let workingDirectory: URL?

    @State private var emulator = TerminalEmulator()
    @State private var inputText: String = ""
    @State private var autoScrollID: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            outputArea

            Divider()

            inputBar
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.95))
        .onAppear {
            emulator.start(in: workingDirectory)
        }
        .onDisappear {
            emulator.stop()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Label("Terminal", systemImage: "terminal")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let dir = emulator.workingDirectory {
                Text(dir.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                emulator.clear()
            } label: {
                Image(systemName: "trash")
                    .help("Clear output")
            }
            .buttonStyle(.borderless)

            if emulator.isRunning {
                Button {
                    emulator.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.red)
                        .help("Stop terminal")
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    emulator.restart(in: workingDirectory)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .help("Restart terminal")
                }
                .buttonStyle(.borderless)
            }

            if ClaudeCodeLauncher.isInstalled() {
                Button {
                    ClaudeCodeLauncher.launch(in: emulator, directory: workingDirectory)
                } label: {
                    Image(systemName: "brain.head.profile")
                        .help("Launch Claude Code")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Output

    private var outputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(emulator.output.isEmpty ? " " : emulator.output)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(nsColor: .textColor))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(8)
                    .id("outputBottom")
            }
            .onChange(of: emulator.output) {
                autoScrollID += 1
                proxy.scrollTo("outputBottom", anchor: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 6) {
            Text("$")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)

            TextField("Enter command...", text: $inputText)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(.plain)
                .onSubmit {
                    guard !inputText.isEmpty else { return }
                    emulator.send(inputText + "\n")
                    inputText = ""
                }
                .disabled(!emulator.isRunning)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

#Preview {
    TerminalView(workingDirectory: nil)
        .frame(width: 600, height: 300)
}
