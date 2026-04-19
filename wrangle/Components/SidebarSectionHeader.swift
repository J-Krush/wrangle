//
//  SidebarSectionHeader.swift
//  Wrangle
//

import SwiftUI

/// Shared sidebar Section header with chevron toggle + optional trailing
/// accessory. Designed to match macOS sidebar density and inherit the native
/// section title color (never overridden to `.secondary`).
struct SidebarSectionHeader<Accessory: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let accessory: () -> Accessory

    init(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self._isExpanded = isExpanded
        self.accessory = accessory
    }

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
            accessory()
        }
    }
}
