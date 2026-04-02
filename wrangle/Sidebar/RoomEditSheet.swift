//
//  RoomEditSheet.swift
//  Wrangle
//
//  Sheet for creating or editing a room with name and color picker.

import SwiftUI

struct RoomEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var colorHex: String
    let isNew: Bool
    let onSave: () -> Void

    private let colors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Red", "#FF3B30"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Teal", "#5AC8FA"),
        ("Yellow", "#FFCC00"),
        ("Indigo", "#5856D6"),
        ("Mint", "#00C7BE"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text(isNew ? "New Room" : "Edit Room")
                .font(.headline)

            TextField("Room name", text: $name)
                .textFieldStyle(.roundedBorder)

            // Color picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(colors, id: \.hex) { color in
                        Button {
                            colorHex = color.hex
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: color.hex) ?? .blue)
                                    .frame(width: 24, height: 24)

                                if colorHex == color.hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(color.name)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isNew ? "Create" : "Save") {
                    onSave()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
