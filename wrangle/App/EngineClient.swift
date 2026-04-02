//
//  EngineClient.swift
//  Wrangle
//
//  Manages the Rust timeline engine process and Unix domain socket connection.
//  Sends workspace snapshots and receives timeline query results via ndjson.

import Foundation

@MainActor
@Observable
class EngineClient {
    private(set) var isConnected = false

    private var process: Process?
    private var socketHandle: FileHandle?
    private var pendingMessages: [Data] = []
    private var readTask: Task<Void, Never>?
    private var responseHandlers: [String: CheckedContinuation<Data?, Never>] = [:]
    private var retryCount = 0
    private let maxRetries = 3
    private var readBuffer = Data()

    private var socketPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Wrangle")
        return dir.appendingPathComponent("engine.sock").path
    }

    private var engineBinaryURL: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("wrangle-engine")
    }

    // MARK: - Lifecycle

    func start() {
        guard process == nil else { return }
        retryCount = 0
        launchEngine()
    }

    func shutdown() {
        guard process != nil else { return }
        sendMessage(.shutdown)

        // Give engine 2 seconds to flush, then force terminate
        let proc = process
        Task.detached {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                if proc?.isRunning == true {
                    proc?.terminate()
                }
            }
        }

        cleanup()
    }

    // MARK: - Sending Messages

    func recordSnapshot(_ snapshot: WorkspaceSnapshot) {
        sendMessage(.recordSnapshot(snapshot))
    }

    func updateRoomIndex(roomID: String, name: String, colorHex: String) {
        sendMessage(.updateRoomIndex(roomID: roomID, name: name, colorHex: colorHex))
    }

    func queryTimeline(startMs: Int64, endMs: Int64, roomID: String? = nil) async -> TimelineResult? {
        let requestID = UUID().uuidString
        let data = await sendAndWait(.queryTimeline(requestID: requestID, startMs: startMs, endMs: endMs, roomID: roomID), requestID: requestID)
        guard let data else { return nil }
        return try? JSONDecoder().decode(TimelineResult.self, from: data)
    }

    func querySnapshot(atMs: Int64) async -> SnapshotQueryResult? {
        let requestID = UUID().uuidString
        let data = await sendAndWait(.querySnapshot(requestID: requestID, timestampMs: atMs), requestID: requestID)
        guard let data else { return nil }
        return try? JSONDecoder().decode(SnapshotQueryResult.self, from: data)
    }

    func queryTimeReport(startMs: Int64, endMs: Int64) async -> TimeReportResult? {
        let requestID = UUID().uuidString
        let data = await sendAndWait(.queryTimeReport(requestID: requestID, startMs: startMs, endMs: endMs), requestID: requestID)
        guard let data else { return nil }
        return try? JSONDecoder().decode(TimeReportResult.self, from: data)
    }

    // MARK: - Internal

    private func launchEngine() {
        guard let binaryURL = engineBinaryURL else {
            print("[EngineClient] wrangle-engine binary not found in bundle")
            return
        }

        guard FileManager.default.isExecutableFile(atPath: binaryURL.path) else {
            print("[EngineClient] wrangle-engine binary is not executable")
            return
        }

        let proc = Process()
        proc.executableURL = binaryURL
        proc.arguments = ["--socket-path", socketPath]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice

        proc.terminationHandler = { [weak self] process in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = false
                self.process = nil
                self.socketHandle = nil

                if process.terminationReason == .uncaughtSignal && self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    print("[EngineClient] Engine crashed, restarting (attempt \(self.retryCount))")
                    try? await Task.sleep(for: .seconds(1))
                    self.launchEngine()
                }
            }
        }

        do {
            try proc.run()
            self.process = proc
            print("[EngineClient] Launched engine (pid: \(proc.processIdentifier))")

            // Poll for socket readiness
            Task {
                await waitForSocket()
            }
        } catch {
            print("[EngineClient] Failed to launch engine: \(error)")
        }
    }

    private func waitForSocket() async {
        // Poll up to 40 times (2 seconds total) for the socket file
        for _ in 0..<40 {
            try? await Task.sleep(for: .milliseconds(50))
            if FileManager.default.fileExists(atPath: socketPath) {
                connectToSocket()
                return
            }
        }
        print("[EngineClient] Timed out waiting for engine socket")
    }

    private func connectToSocket() {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            print("[EngineClient] Failed to create socket")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let bound = ptr.withMemoryRebound(to: Int8.self, capacity: Int(104)) { dest in
                pathBytes.withUnsafeBufferPointer { src in
                    let count = min(src.count, 104)
                    dest.update(from: src.baseAddress!, count: count)
                    return count
                }
            }
            _ = bound
        }

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard result == 0 else {
            close(fd)
            print("[EngineClient] Failed to connect to socket: \(errno)")
            return
        }

        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        self.socketHandle = handle
        self.isConnected = true
        self.retryCount = 0
        print("[EngineClient] Connected to engine")

        // Flush pending messages
        for data in pendingMessages {
            try? handle.write(contentsOf: data)
        }
        pendingMessages.removeAll()

        // Start reading responses
        startReading(handle: handle)
    }

    private func startReading(handle: FileHandle) {
        readTask?.cancel()
        readTask = Task.detached { [weak self] in
            let fd = handle.fileDescriptor
            var buffer = [UInt8](repeating: 0, count: 4096)

            while !Task.isCancelled {
                let bytesRead = read(fd, &buffer, buffer.count)
                if bytesRead <= 0 { break }

                let chunk = Data(buffer[0..<bytesRead])
                await MainActor.run { [weak self] in
                    self?.handleIncomingData(chunk)
                }
            }
        }
    }

    private func handleIncomingData(_ data: Data) {
        readBuffer.append(data)

        // Process complete lines (ndjson)
        while let newlineIndex = readBuffer.firstIndex(of: UInt8(ascii: "\n")) {
            let lineData = readBuffer[readBuffer.startIndex..<newlineIndex]
            readBuffer = Data(readBuffer[(newlineIndex + 1)...])

            guard !lineData.isEmpty else { continue }

            // Parse the type field to route to the right handler
            if let envelope = try? JSONDecoder().decode(EngineInbound.self, from: Data(lineData)) {
                routeResponse(type: envelope.type, data: Data(lineData))
            }
        }
    }

    private func routeResponse(type: String, data: Data) {
        // Extract request_id from response to match with pending continuations
        struct RequestIDExtractor: Decodable {
            let requestID: String?
            enum CodingKeys: String, CodingKey {
                case requestID = "request_id"
            }
        }

        if let extractor = try? JSONDecoder().decode(RequestIDExtractor.self, from: data),
           let requestID = extractor.requestID,
           let continuation = responseHandlers.removeValue(forKey: requestID) {
            continuation.resume(returning: data)
        }

        // snapshot_written is fire-and-forget, no handler needed
    }

    private func sendMessage(_ message: EngineOutbound) {
        guard let data = try? JSONEncoder().encode(message),
              var payload = String(data: data, encoding: .utf8) else { return }
        payload += "\n"

        guard let payloadData = payload.data(using: .utf8) else { return }

        if isConnected, let handle = socketHandle {
            try? handle.write(contentsOf: payloadData)
        } else {
            pendingMessages.append(payloadData)
        }
    }

    private func sendAndWait(_ message: EngineOutbound, requestID: String) async -> Data? {
        return await withCheckedContinuation { continuation in
            responseHandlers[requestID] = continuation
            sendMessage(message)

            // Timeout after 5 seconds
            Task {
                try? await Task.sleep(for: .seconds(5))
                if let cont = responseHandlers.removeValue(forKey: requestID) {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    private func cleanup() {
        readTask?.cancel()
        readTask = nil
        socketHandle = nil
        process = nil
        isConnected = false
        pendingMessages.removeAll()

        // Cancel all pending continuations
        for (_, continuation) in responseHandlers {
            continuation.resume(returning: nil)
        }
        responseHandlers.removeAll()
    }
}
