//
//  CollapsibleSection.swift
//  Wrangle
//

import SwiftUI

/// Collapsible VStack-style section used on the Project Overview page and
/// any other non-List layout. Persists expanded state under `storageKey`.
struct CollapsibleVStackSection<Content: View, Accessory: View>: View {
    let title: String
    private let storage: String
    @AppStorage private var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let accessory: () -> Accessory

    init(
        _ title: String,
        storageKey: String,
        defaultExpanded: Bool = true,
        @ViewBuilder accessory: @escaping () -> Accessory,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.storage = storageKey
        self.content = content
        self.accessory = accessory
        _isExpanded = AppStorage(wrappedValue: defaultExpanded, storageKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                accessory()
                Spacer()
            }
            if isExpanded {
                content()
            }
        }
    }
}

extension CollapsibleVStackSection where Accessory == EmptyView {
    init(
        _ title: String,
        storageKey: String,
        defaultExpanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title,
            storageKey: storageKey,
            defaultExpanded: defaultExpanded,
            accessory: { EmptyView() },
            content: content
        )
    }
}
