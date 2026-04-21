#!/usr/bin/env swift
// screenshot-tool.swift — Floating toolbar for high-res window screenshots via ScreenCaptureKit.
//
// Usage: swift scripts/screenshot-tool.swift
//
// Captures at 2x or 3x Retina resolution using ScreenCaptureKit's single-frame API.
// Saves PNGs to screenshots/raw/ (ready for polish-screenshot.py).

import AppKit
import ScreenCaptureKit
import CoreMedia

// MARK: - Output Directory

let outputDir: URL = {
    let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let projectDir = scriptDir.deletingLastPathComponent()
    let rawDir = projectDir.appendingPathComponent("screenshots/raw")
    try? FileManager.default.createDirectory(at: rawDir, withIntermediateDirectories: true)
    return rawDir
}()

// MARK: - Single Frame Grabber (captures one frame from SCStream)

class SingleFrameGrabber: NSObject, SCStreamOutput {
    private var continuation: CheckedContinuation<CGImage, any Error>?
    private var captured = false

    func waitForFrame() async throws -> CGImage {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, !captured else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Skip blank/idle frames by checking pixel buffer has real dimensions
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard width > 0, height > 0 else { return }

        captured = true

        // Create CGImage directly from the pixel buffer via CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            continuation?.resume(throwing: NSError(domain: "ScreenshotTool", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage from frame"]))
            return
        }

        continuation?.resume(returning: cgImage)
    }
}

// MARK: - Floating Panel (allows key status for popup buttons)

class ToolbarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { NSApp.terminate(nil) }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: ToolbarPanel!
    var windowPicker: NSPopUpButton!
    var scaleControl: NSSegmentedControl!
    var timerControl: NSSegmentedControl!
    var captureButton: NSButton!
    var statusLabel: NSTextField!
    var dimensionsLabel: NSTextField!

    var scWindows: [SCWindow] = []
    var lastSaved: URL?

    // Timer delay options in seconds, parallel to timerControl segments.
    let timerDelays: [Int] = [0, 3, 5, 10]

    func applicationDidFinishLaunching(_ note: Notification) {
        buildUI()
        loadWindows()
    }

    // MARK: UI

    func buildUI() {
        let panelW: CGFloat = 800
        let panelH: CGFloat = 68
        let screen = NSScreen.main!.frame
        let frame = NSRect(
            x: (screen.width - panelW) / 2,
            y: screen.maxY - panelH - 40,
            width: panelW,
            height: panelH
        )

        panel = ToolbarPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.appearance = NSAppearance(named: .darkAqua)

        // Vibrancy background
        let bg = NSVisualEffectView()
        bg.material = .hudWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 14
        bg.layer?.masksToBounds = true
        panel.contentView = bg

        // ── Top row: controls ──

        let refreshBtn = makeButton(symbol: "arrow.clockwise", action: #selector(refreshClicked))
        refreshBtn.toolTip = "Refresh window list"

        windowPicker = NSPopUpButton(frame: .zero, pullsDown: false)
        windowPicker.controlSize = .regular
        windowPicker.target = self
        windowPicker.action = #selector(windowChanged)
        windowPicker.setContentHuggingPriority(.defaultLow, for: .horizontal)

        scaleControl = NSSegmentedControl(labels: ["2x", "3x"], trackingMode: .selectOne, target: self, action: #selector(scaleChanged))
        scaleControl.selectedSegment = 0
        scaleControl.controlSize = .regular
        scaleControl.segmentDistribution = .fillEqually
        scaleControl.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let timerLabels = timerDelays.map { $0 == 0 ? "Now" : "\($0)s" }
        timerControl = NSSegmentedControl(labels: timerLabels, trackingMode: .selectOne, target: self, action: nil)
        timerControl.selectedSegment = 0
        timerControl.controlSize = .regular
        timerControl.segmentDistribution = .fillEqually
        timerControl.toolTip = "Delay before capture — lets you position the mouse"
        timerControl.widthAnchor.constraint(equalToConstant: 160).isActive = true

        captureButton = NSButton(title: "Capture", target: self, action: #selector(captureClicked))
        captureButton.bezelStyle = .rounded
        captureButton.controlSize = .regular
        captureButton.keyEquivalent = "\r"
        if let img = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Capture") {
            captureButton.image = img
            captureButton.imagePosition = .imageLeading
        }

        let copyBtn = makeButton(symbol: "doc.on.doc", action: #selector(copyClicked))
        copyBtn.toolTip = "Copy last screenshot to clipboard"

        let revealBtn = makeButton(symbol: "folder", action: #selector(revealClicked))
        revealBtn.toolTip = "Reveal in Finder"

        let controlStack = NSStackView(views: [refreshBtn, windowPicker, scaleControl, timerControl, captureButton, copyBtn, revealBtn])
        controlStack.orientation = .horizontal
        controlStack.spacing = 8
        controlStack.alignment = .centerY

        // ── Bottom row: status + dimensions ──

        statusLabel = makeLabel("Ready")
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        dimensionsLabel = makeLabel("")
        dimensionsLabel.textColor = .tertiaryLabelColor
        dimensionsLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        dimensionsLabel.alignment = .right

        let infoStack = NSStackView(views: [statusLabel, dimensionsLabel])
        infoStack.orientation = .horizontal
        infoStack.spacing = 8

        // ── Main stack ──

        let mainStack = NSStackView(views: [controlStack, infoStack])
        mainStack.orientation = .vertical
        mainStack.spacing = 4
        mainStack.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        bg.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: bg.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bg.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
        ])

        // ── Menu (Cmd+Q) ──

        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Screenshot Tool", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu

        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func makeButton(symbol: String, action: Selector) -> NSButton {
        let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            ?? NSImage(named: NSImage.refreshTemplateName)!
        let btn = NSButton(image: img, target: self, action: action)
        btn.bezelStyle = .recessed
        btn.isBordered = false
        btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
        return btn
    }

    func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }

    // MARK: Window Discovery

    func loadWindows() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                let windows = content.windows.filter { w in
                    guard let app = w.owningApplication, !app.applicationName.isEmpty else { return false }
                    guard w.frame.width > 50, w.frame.height > 50 else { return false }
                    let skip = ["SystemUIServer", "Control Center", "Notification Center",
                                "WindowManager", "Window Server", "Dock"]
                    return !skip.contains(app.applicationName)
                }.sorted { a, b in
                    let aName = a.owningApplication?.applicationName ?? ""
                    let bName = b.owningApplication?.applicationName ?? ""
                    return aName.localizedCaseInsensitiveCompare(bName) == .orderedAscending
                }

                await MainActor.run {
                    self.scWindows = windows
                    self.windowPicker.removeAllItems()

                    if windows.isEmpty {
                        self.windowPicker.addItem(withTitle: "No windows found")
                        self.captureButton.isEnabled = false
                    } else {
                        for w in windows {
                            let app = w.owningApplication?.applicationName ?? "Unknown"
                            let title = w.title ?? ""
                            let size = "\(Int(w.frame.width))x\(Int(w.frame.height))"
                            let label = title.isEmpty
                                ? "\(app)  (\(size))"
                                : "\(app) — \(title)  (\(size))"
                            self.windowPicker.addItem(withTitle: label)
                        }
                        self.captureButton.isEnabled = true

                        // Pre-select Wrangle if available
                        if let idx = windows.firstIndex(where: {
                            $0.owningApplication?.applicationName.lowercased() == "wrangle"
                        }) {
                            self.windowPicker.selectItem(at: idx)
                        }
                    }
                    self.updateDimensions()
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.stringValue = "Error: \(error.localizedDescription)"
                    self.statusLabel.textColor = .systemRed
                }
            }
        }
    }

    func updateDimensions() {
        let idx = windowPicker.indexOfSelectedItem
        guard idx >= 0, idx < scWindows.count else {
            dimensionsLabel.stringValue = ""
            return
        }
        let w = scWindows[idx]
        let scale = scaleControl.selectedSegment == 0 ? 2 : 3
        let pw = Int(w.frame.width) * scale
        let ph = Int(w.frame.height) * scale
        dimensionsLabel.stringValue = "\(pw) x \(ph) px"
    }

    // MARK: Actions

    @objc func refreshClicked(_ sender: Any?) {
        statusLabel.stringValue = "Refreshing..."
        statusLabel.textColor = .secondaryLabelColor
        loadWindows()
    }

    @objc func windowChanged(_ sender: Any?) {
        updateDimensions()
    }

    @objc func scaleChanged(_ sender: Any?) {
        updateDimensions()
    }

    @objc func captureClicked(_ sender: Any?) {
        let idx = windowPicker.indexOfSelectedItem
        guard idx >= 0, idx < scWindows.count else { return }

        let window = scWindows[idx]
        let scale = scaleControl.selectedSegment == 0 ? 2 : 3
        let delay = timerDelays[timerControl.selectedSegment]

        captureButton.isEnabled = false

        Task {
            // Countdown: tick once per second so the user can place the cursor.
            if delay > 0 {
                for remaining in stride(from: delay, through: 1, by: -1) {
                    await MainActor.run {
                        self.statusLabel.stringValue = "Capturing in \(remaining)s…"
                        self.statusLabel.textColor = .systemOrange
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }

            await MainActor.run {
                self.statusLabel.stringValue = "Capturing..."
                self.statusLabel.textColor = .secondaryLabelColor
            }

            do {
                // Always capture at native 2x Retina — this is what the display
                // actually renders. 3x on a 2x display can't produce new detail,
                // so we capture at 2x and upscale with high-quality interpolation.
                let nativeScale = 2
                let filter = SCContentFilter(desktopIndependentWindow: window)
                let config = SCStreamConfiguration()
                config.width = Int(window.frame.width) * nativeScale
                config.height = Int(window.frame.height) * nativeScale
                config.captureResolution = .best
                // If the user set a timer, they likely want the cursor they
                // just positioned to appear in the shot.
                config.showsCursor = delay > 0
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.minimumFrameInterval = CMTime(value: 1, timescale: 30)

                let grabber = SingleFrameGrabber()
                let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream.addStreamOutput(grabber, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
                try await stream.startCapture()

                let nativeImage = try await grabber.waitForFrame()
                try await stream.stopCapture()

                let finalImage: CGImage
                let scaleLabel: String

                if scale == 3 {
                    // Upscale native 2x → 3x with high-quality interpolation
                    let targetW = Int(window.frame.width) * 3
                    let targetH = Int(window.frame.height) * 3
                    guard let ctx = CGContext(
                        data: nil, width: targetW, height: targetH,
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
                    ) else {
                        throw NSError(domain: "ScreenshotTool", code: -2,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to create 3x context"])
                    }
                    ctx.interpolationQuality = .high
                    ctx.draw(nativeImage, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))
                    guard let scaled = ctx.makeImage() else {
                        throw NSError(domain: "ScreenshotTool", code: -3,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to render 3x image"])
                    }
                    finalImage = scaled
                    scaleLabel = "3x"
                } else {
                    finalImage = nativeImage
                    scaleLabel = "2x-native"
                }

                // Save as PNG
                let appName = window.owningApplication?.applicationName ?? "window"
                let safeName = appName.replacingOccurrences(of: " ", with: "-")
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd-HHmmss"
                let timestamp = fmt.string(from: Date())
                let filename = "\(safeName)-\(timestamp)-\(scaleLabel).png"
                let url = outputDir.appendingPathComponent(filename)

                let rep = NSBitmapImageRep(cgImage: finalImage)
                guard let data = rep.representation(using: .png, properties: [:]) else {
                    throw NSError(domain: "ScreenshotTool", code: -4,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
                }
                try data.write(to: url)

                await MainActor.run {
                    self.lastSaved = url
                    let fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                    self.statusLabel.stringValue = "✓ \(finalImage.width)x\(finalImage.height) \(scaleLabel)  (\(fileSize))"
                    self.statusLabel.textColor = .systemGreen
                    self.captureButton.isEnabled = true
                    NSSound(named: .init("Tink"))?.play()
                }
            } catch {
                await MainActor.run {
                    self.captureButton.isEnabled = true
                    self.statusLabel.textColor = .systemRed
                    self.statusLabel.stringValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    @objc func copyClicked(_ sender: Any?) {
        guard let url = lastSaved, let image = NSImage(contentsOf: url) else {
            statusLabel.stringValue = "Nothing to copy yet"
            statusLabel.textColor = .secondaryLabelColor
            return
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
        statusLabel.stringValue = "Copied to clipboard"
        statusLabel.textColor = .systemBlue
    }

    @objc func revealClicked(_ sender: Any?) {
        if let url = lastSaved {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(outputDir)
        }
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
