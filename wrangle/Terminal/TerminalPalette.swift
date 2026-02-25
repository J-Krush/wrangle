//
//  TerminalPalette.swift
//  wrangle
//
//  ANSI color palette for the embedded terminal.
//  Uses OSC 4 escape sequences to set colors, avoiding SwiftTerm's
//  Color type naming collision with SwiftUI.Color.
//

import Foundation
import SwiftTerm

enum TerminalPalette {
    /// iTerm-default ANSI 16-color palette as (r, g, b) tuples.
    private static let colors: [(UInt8, UInt8, UInt8)] = [
        (0x00, 0x00, 0x00),  // 0: Black
        (0xc9, 0x1b, 0x00),  // 1: Red
        (0x00, 0xc2, 0x00),  // 2: Green
        (0xc7, 0xc4, 0x00),  // 3: Yellow
        (0x02, 0x25, 0xc7),  // 4: Blue
        (0xc9, 0x30, 0xc7),  // 5: Magenta
        (0x00, 0xc5, 0xc7),  // 6: Cyan
        (0xc7, 0xc7, 0xc7),  // 7: White
        (0x68, 0x68, 0x68),  // 8: Bright Black
        (0xff, 0x6e, 0x67),  // 9: Bright Red
        (0x5f, 0xfa, 0x68),  // 10: Bright Green
        (0xff, 0xfc, 0x67),  // 11: Bright Yellow
        (0x68, 0x71, 0xff),  // 12: Bright Blue
        (0xff, 0x76, 0xff),  // 13: Bright Magenta
        (0x60, 0xfd, 0xff),  // 14: Bright Cyan
        (0xff, 0xff, 0xff),  // 15: Bright White
    ]

    /// Installs the iTerm-default ANSI palette on a terminal view
    /// by feeding OSC 4 escape sequences into the terminal emulator.
    /// Format: ESC ] 4 ; index ; rgb:rr/gg/bb ESC \
    static func install(on terminalView: LocalProcessTerminalView) {
        let terminal = terminalView.getTerminal()
        for (index, (r, g, b)) in colors.enumerated() {
            let seq = "\u{1b}]4;\(index);rgb:\(hex(r))/\(hex(g))/\(hex(b))\u{1b}\\"
            let bytes = Array(seq.utf8)
            terminal.feed(byteArray: bytes)
        }
    }

    private static func hex(_ value: UInt8) -> String {
        String(format: "%02x", value)
    }
}
