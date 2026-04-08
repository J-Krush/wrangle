//
//  BrowserContainerView.swift
//  Wrangle
//

import AppKit
import WebKit

/// Wraps a WKWebView to add hit-test gating for inactive browser tabs,
/// mirroring the TerminalContainerView pattern.
class BrowserContainerView: NSView {
    private(set) var activeWebView: WKWebView?

    var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else { return }
            if isActive {
                registerForDraggedTypes([.fileURL])
            } else {
                unregisterDraggedTypes()
            }
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - WebView Management

    func setActiveWebView(_ webView: WKWebView) {
        // Hide current webview
        activeWebView?.isHidden = true

        activeWebView = webView

        if webView.superview !== self {
            webView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: topAnchor),
                webView.bottomAnchor.constraint(equalTo: bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }

        webView.isHidden = false
    }

    func hideAllWebViews() {
        for subview in subviews {
            subview.isHidden = true
        }
        activeWebView = nil
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isActive else { return nil }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        if let webView = activeWebView {
            window?.makeFirstResponder(webView)
        }
        super.mouseDown(with: event)
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard isActive else { return [] }
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) ? .copy : []
    }

    override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard isActive else { return false }
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard isActive else { return false }
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let firstURL = urls.first else {
            return false
        }
        // Navigate active webview to dropped URL
        activeWebView?.load(URLRequest(url: firstURL))
        return true
    }
}
