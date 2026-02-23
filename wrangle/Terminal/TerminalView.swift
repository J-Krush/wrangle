//
//  TerminalView.swift
//  wrangle
//
//  Created by John Kreisher on 2/21/26.
//
//  Legacy standalone terminal view — superseded by SwiftTermView + TerminalTabContentView.
//  Kept for reference; not used in the active UI.

import SwiftUI

struct LegacyTerminalView: View {
    let emulator: TerminalEmulator
    let workingDirectory: URL?

    var body: some View {
        Text("Legacy terminal view — use TerminalTabContentView instead")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
