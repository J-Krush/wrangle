//
//  PlaybackBannerView.swift
//  Wrangle
//
//  Banner shown at the top of the content area during timeline playback.
//  Displays the room name, timestamp, and Restore/Back to now buttons.

import SwiftUI

struct PlaybackBannerView: View {
    @Environment(AppState.self) private var appState
    let playback: TimelinePlayback

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                if let hex = playback.roomColorHex {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 8, height: 8)
                }
                Text("Viewing \(playback.roomName)")
                    .font(.system(size: 12, weight: .medium))
            }

            Text("·")
                .foregroundStyle(.tertiary)

            Text(playback.formattedTime)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                appState.restoreFromPlayback()
            } label: {
                Text("Restore")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button {
                appState.exitPlayback()
            } label: {
                Text("Back to now")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.08))
        .overlay(alignment: .bottom) { Divider() }
    }
}
