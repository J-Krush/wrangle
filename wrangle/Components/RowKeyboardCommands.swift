//
//  RowKeyboardCommands.swift
//  Wrangle
//
//  Phase 12 / UIX-21: shared keyboard-command modifier for sidebar rows.
//  Replaces the hover-only DeleteKeyHandler that lived privately inside
//  NestedBookmarkSubSection with a symmetric pattern usable by both
//  Scratch Pads and Bookmarks.
//
//  Activation: `enabled` is typically the row's `isHovering` state. When the
//  row is hovered, Return/Delete fire the respective callback. Either
//  callback may be nil to disable that key on that row.
//

import SwiftUI

struct RowKeyboardCommands: ViewModifier {
    let enabled: Bool
    var onReturn: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    func body(content: Content) -> some View {
        content
            .focusable(enabled)
            .onKeyPress(.return) {
                guard enabled, let onReturn else { return .ignored }
                onReturn()
                return .handled
            }
            .onKeyPress(.delete) {
                guard enabled, let onDelete else { return .ignored }
                onDelete()
                return .handled
            }
    }
}

extension View {
    func rowKeyboardCommands(
        enabled: Bool,
        onReturn: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        modifier(RowKeyboardCommands(enabled: enabled, onReturn: onReturn, onDelete: onDelete))
    }
}
