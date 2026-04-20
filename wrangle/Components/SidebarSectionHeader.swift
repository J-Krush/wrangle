//
//  SidebarSectionHeader.swift
//  Wrangle
//

import SwiftUI

/// Static sidebar section header — nav-only.
///
/// Phase 10 stripped creation affordances from section headers. Phase 12
/// refinement went further: sidebar sections are no longer collapsible. The
/// chevron + toggle are gone; sections always render their content (still
/// gated by hide-when-empty at the caller). Optional trailing slot for
/// navigation-only accessories (e.g., the Bookmarks book icon).
///
/// Overview cards (`CollapsibleVStackSection`) keep collapsibility; this
/// component is sidebar-specific.
struct SidebarSectionHeader<Trailing: View>: View {
    let title: String
    var count: Int? = nil
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.trailing, 8)
    }
}

extension SidebarSectionHeader where Trailing == EmptyView {
    init(title: String, count: Int? = nil) {
        self.init(title: title, count: count, trailing: { EmptyView() })
    }
}
