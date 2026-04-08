//
//  SystemMetrics.swift
//  Wrangle
//

import Foundation
import Darwin

@Observable
@MainActor
final class SystemMetrics {
    var ramUsage: Double = 0
    var cpuUsage: Double = 0
    var diskUsage: Double = 0
    var runningSessionCount: Int = 0

    private var previousCPUTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    private var monitoringTask: Task<Void, Never>?

    /// Weak ref to coordinator to count running terminal sessions across all windows
    weak var coordinator: AppCoordinator?

    func startMonitoring() {
        guard monitoringTask == nil else { return }
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.update()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    private func update() {
        ramUsage = Self.fetchRAMUsage()
        cpuUsage = fetchCPUUsage()
        diskUsage = Self.fetchDiskUsage()
        runningSessionCount = fetchRunningSessionCount()
    }

    // MARK: - RAM
    // Matches Activity Monitor's "Memory Used" = total - free - speculative - purgeable - external
    // which equals app memory + wired + compressed

    private static func fetchRAMUsage() -> Double {
        let host = mach_host_self()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var stats = vm_statistics64_data_t()

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics64(host, HOST_VM_INFO64, intPtr, &size)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = UInt64(vm_kernel_page_size)

        // Memory pressure: non-reclaimable (active + wired) vs reclaimable (free + inactive + purgeable)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let free = UInt64(stats.free_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let purgeable = UInt64(stats.purgeable_count) * pageSize

        let pressureUsed = active + wired
        let available = free + inactive + purgeable
        let pressureBase = pressureUsed + available

        guard pressureBase > 0 else { return 0 }
        return Double(pressureUsed) / Double(pressureBase) * 100
    }

    // MARK: - CPU

    private func fetchCPUUsage() -> Double {
        let host = mach_host_self()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info_data_t()

        let result = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(host, HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let user = info.cpu_ticks.0
        let system = info.cpu_ticks.1
        let idle = info.cpu_ticks.2
        let nice = info.cpu_ticks.3

        defer {
            previousCPUTicks = (user: user, system: system, idle: idle, nice: nice)
        }

        guard let prev = previousCPUTicks else { return 0 }

        let dUser = Double(user &- prev.user)
        let dSystem = Double(system &- prev.system)
        let dIdle = Double(idle &- prev.idle)
        let dNice = Double(nice &- prev.nice)
        let totalDelta = dUser + dSystem + dIdle + dNice

        guard totalDelta > 0 else { return 0 }
        return (dUser + dSystem + dNice) / totalDelta * 100
    }

    // MARK: - Disk
    // Uses volumeAvailableCapacityForImportantUsage which excludes purgeable space,
    // matching what System Settings shows

    private static func fetchDiskUsage() -> Double {
        guard let url = URL(string: "file:///"),
              let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage,
              total > 0 else { return 0 }

        let used = Int64(total) - available
        return Double(used) / Double(total) * 100
    }

    // MARK: - Running Sessions (Wrangle terminals only)

    private func fetchRunningSessionCount() -> Int {
        guard let coordinator else { return 0 }
        var count = 0
        for state in coordinator.windowStates.values {
            count += state.tabs.filter { $0.terminalSession?.isRunning == true }.count
        }
        return count
    }
}
