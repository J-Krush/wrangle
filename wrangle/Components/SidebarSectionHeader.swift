//
//  SidebarSectionHeader.swift
//  Wrangle
//

import SwiftUI

/// Shared sidebar Section header with chevron toggle. Navigation-only —
/// any creation affordances live in `UnifiedAddMenu` (plan 10-01) and are
/// presented exclusively from the sidebar bottom-bar `+` and the Project
/// Overview header `+` (Phase 10 D-08 / D-11).
///
/// Optional `count` renders only when collapsed (Phase 12 D-01), styled
/// `.system(size: 10)` + `.tertiary` to match the canonical treatment.
struct SidebarSectionHeader: View {
    let title: String
    @Binding var isExpanded: Bool
    var count: Int? = nil

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
                    if let count, !isExpanded {
                        Text("\(count)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}
