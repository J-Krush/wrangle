//
//  SystemMetricsView.swift
//  Wrangle
//

import SwiftUI

struct SystemMetricsView: View {
    let metrics: SystemMetrics
    @AppStorage("showSystemMetrics") private var showSystemMetrics: Bool = true

    var body: some View {
        if showSystemMetrics {
            HStack(spacing: 20) {
                MetricBar(label: "RAM", value: metrics.ramUsage, color: .blue)
                MetricBar(label: "CPU", value: metrics.cpuUsage, color: .green)
                MetricBar(label: "disk", value: metrics.diskUsage, color: .gray)

                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("\(metrics.runningSessionCount) sessions running")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            .fixedSize()
        }
    }
}

// MARK: - Metric Bar

private struct MetricBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 60, height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: 60 * min(CGFloat(value) / 100, 1))
                }

            Text("\(Int(value))%")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }
}
