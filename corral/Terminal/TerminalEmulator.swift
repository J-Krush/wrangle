//
//  TerminalEmulator.swift
//  corral
//
//  Created by John Kreisher on 2/21/26.
//

import Foundation
import Darwin

@Observable
class TerminalEmulator {
    var output: String = ""
    var isRunning: Bool = false
    var workingDirectory: URL?

    private var masterFD: Int32 = -1
    private var childPID: pid_t = 0
    private var readSource: DispatchSourceRead?

    func start(in directory: URL? = nil) {
        guard !isRunning else { return }
        workingDirectory = directory

        var fd: Int32 = 0
        let pid = forkpty(&fd, nil, nil, nil)

        if pid == 0 {
            // Child process — runs in a forked address space, no actor isolation applies.
            if let dir = directory?.path {
                chdir(dir)
            }

            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

            // Configure terminal environment
            setenv("TERM", "xterm-256color", 1)
            setenv("LANG", "en_US.UTF-8", 1)

            // exec the login shell
            let cArgs = [strdup(shell), strdup("-l"), nil]
            execv(shell, cArgs)

            // If execv returns, it failed
            _exit(1)
        } else if pid > 0 {
            // Parent process
            self.masterFD = fd
            self.childPID = pid
            self.isRunning = true
            startReading()
        } else {
            // fork failed
            self.isRunning = false
        }
    }

    func send(_ input: String) {
        guard isRunning, masterFD >= 0 else { return }
        input.utf8CString.withUnsafeBufferPointer { buffer in
            // utf8CString includes a null terminator; write only the actual bytes
            let count = buffer.count - 1
            guard count > 0 else { return }
            buffer.baseAddress?.withMemoryRebound(to: UInt8.self, capacity: count) { ptr in
                _ = Darwin.write(masterFD, ptr, count)
            }
        }
    }

    func stop() {
        readSource?.cancel()
        readSource = nil

        if childPID > 0 {
            kill(childPID, SIGTERM)

            // Reap the child to avoid zombies
            var status: Int32 = 0
            waitpid(childPID, &status, WNOHANG)
            childPID = 0
        }

        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }

        isRunning = false
    }

    func clear() {
        output = ""
    }

    func restart(in directory: URL? = nil) {
        stop()
        output = ""
        start(in: directory ?? workingDirectory)
    }

    // MARK: - Private

    private func startReading() {
        let fd = masterFD
        let source = DispatchSource.makeReadSource(
            fileDescriptor: fd,
            queue: DispatchQueue.global(qos: .userInteractive)
        )

        source.setEventHandler { [weak self] in
            self?.handleRead(fd: fd)
        }

        source.setCancelHandler {
            // Nothing to clean up here; stop() manages the fd lifecycle
        }

        self.readSource = source
        source.resume()
    }

    /// Reads available data from the PTY and appends it to output on the main actor.
    /// Runs on the dispatch source's background queue.
    nonisolated private func handleRead(fd: Int32) {
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let bytesRead = Darwin.read(fd, buffer, bufferSize)

        if bytesRead > 0 {
            if let raw = String(bytes: UnsafeBufferPointer(start: buffer, count: bytesRead), encoding: .utf8) {
                let cleaned = TerminalEmulator.stripANSI(raw)
                Task { @MainActor [weak self] in
                    self?.output.append(cleaned)
                }
            }
        } else if bytesRead <= 0 {
            // EOF or error — the child process has exited
            Task { @MainActor [weak self] in
                self?.handleProcessExit()
            }
        }
    }

    private func handleProcessExit() {
        readSource?.cancel()
        readSource = nil

        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }

        if childPID > 0 {
            var status: Int32 = 0
            waitpid(childPID, &status, WNOHANG)
            childPID = 0
        }

        isRunning = false
    }

    /// Strips ANSI escape sequences from terminal output so raw control codes
    /// don't appear as garbage in the text view.
    nonisolated static func stripANSI(_ string: String) -> String {
        // Matches CSI sequences (ESC [ ... final byte), OSC sequences (ESC ] ... ST),
        // and simple two-byte escape sequences (ESC followed by one char).
        let pattern = #"\x1B\[[0-9;?]*[A-Za-z]|\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)|\x1B[()][A-Za-z0-9]|\x1B[A-Za-z]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return string
        }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, range: range, withTemplate: "")
    }

    deinit {
        readSource?.cancel()
        readSource = nil

        if childPID > 0 {
            kill(childPID, SIGTERM)
            var status: Int32 = 0
            waitpid(childPID, &status, WNOHANG)
        }

        if masterFD >= 0 {
            close(masterFD)
        }
    }
}
