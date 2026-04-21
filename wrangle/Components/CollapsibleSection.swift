//
//  CollapsibleSection.swift
//  Wrangle
//

import SwiftUI

/// Collapsible VStack-style section used on the Project Overview page and
/// any other non-List layout. Persists expanded state under `storageKey`.
///
/// Optional `count` renders only when collapsed (Phase 12 D-04), styled
/// `.system(size: 10)` + `.tertiary` to match the sidebar count treatment.
struct CollapsibleVStackSection<Content: View, Accessory: View>: View {
    let title: String
    private let storage: String
    let count: Int?
    @AppStorage private var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let accessory: () -> Accessory

    init(
        _ title: String,
        storageKey: String,
        defaultExpanded: Bool = true,
        count: Int? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.storage = storageKey
        self.count = count
        self.content = content
        self.accessory = accessory
        _isExpanded = AppStorage(wrappedValue: defaultExpanded, storageKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // NOTE: collapse UI (chevron + toggle) and count badge
                // intentionally commented out for this release. The user
                // may re-expose collapsing later to let people clean up
                // their overview; restoring the behavior is as simple as
                // uncommenting the Button block below and the `if isExpanded`
                // gate at the bottom of this VStack. `isExpanded`, `storage`,
                // `count`, and `storageKey` on both inits are preserved so
                // every call site continues to compile unchanged.
                //
                // Button {
                //     withAnimation(.snappy(duration: 0.18)) {
                //         isExpanded.toggle()
                //     }
                // } label: {
                //     // Chevron centers against the title+count group (outer HStack
                //     // defaults to .center). Count baseline-aligns with the larger
                //     // title inside an inner HStack.
                //     HStack(spacing: 6) {
                //         Image(systemName: "chevron.right")
                //             .font(.caption.weight(.semibold))
                //             .foregroundStyle(.secondary)
                //             .rotationEffect(.degrees(isExpanded ? 90 : 0))
                //         HStack(alignment: .firstTextBaseline, spacing: 6) {
                //             Text(title)
                //                 .font(.headline)
                //                 .foregroundStyle(.secondary)
                //             if let count, !isExpanded {
                //                 Text("\(count)")
                //                     .font(.system(size: 10))
                //                     .foregroundStyle(.tertiary)
                //             }
                //         }
                //     }
                //     .contentShape(Rectangle())
                // }
                // .buttonStyle(.plain)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                accessory()
                Spacer()
            }
            // NOTE: `if isExpanded { content() }` — gate removed so that
            // users who had previously collapsed a section still see their
            // data. Re-add the `if isExpanded` check when restoring the
            // chevron above.
            content()
        }
    }
}

extension CollapsibleVStackSection where Accessory == EmptyView {
    init(
        _ title: String,
        storageKey: String,
        defaultExpanded: Bool = true,
        count: Int? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title,
            storageKey: storageKey,
            defaultExpanded: defaultExpanded,
            count: count,
            accessory: { EmptyView() },
            content: content
        )
    }
}
