//
//  SidebarSectionHeader.swift
//  Wrangle
//

import SwiftUI

/// Shared sidebar Section header with chevron toggle.
///
/// Phase 10 kept this nav-only by stripping creation affordances (+/…/Import).
/// Phase 12 re-introduces an optional `trailing` accessory slot specifically
/// for *navigation* affordances (e.g., the Bookmarks book icon that opens a
/// popover). Creation affordances still belong in `UnifiedAddMenu`.
///
/// Optional `count` renders only when collapsed, styled `.system(size: 10)` +
/// `.tertiary` to match the canonical treatment.
struct SidebarSectionHeader<Trailing: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    var count: Int? = nil
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.snappy(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
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
            trailing()
        }
        // Symmetric horizontal padding: match the visual gap from chevron-to-left-edge
        // with trailing-accessory-to-right-edge (trailing-only; don't shift chevron).
        .padding(.trailing, 8)
    }
}

extension SidebarSectionHeader where Trailing == EmptyView {
    init(title: String, isExpanded: Binding<Bool>, count: Int? = nil) {
        self.init(title: title, isExpanded: isExpanded, count: count, trailing: { EmptyView() })
    }
}
