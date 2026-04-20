//
//  SidebarSectionHeader.swift
//  Wrangle
//

import SwiftUI

/// Shared sidebar Section header with chevron toggle. Navigation-only —
/// any creation affordances live in `UnifiedAddMenu` (plan 10-01) and are
/// presented exclusively from the sidebar bottom-bar `+` and the Project
/// Overview header `+` (Phase 10 D-08 / D-11).
struct SidebarSectionHeader: View {
    let title: String
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.snappy(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Text(title)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}
