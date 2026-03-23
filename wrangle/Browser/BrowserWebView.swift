//
//  BrowserWebView.swift
//  Wrangle
//

import SwiftUI
import WebKit

// MARK: - Weak Script Message Handler

/// Prevents retain cycle: WKUserContentController strongly retains its
/// script message handlers, so we use a weak proxy to break the cycle.
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - BrowserWebView

struct BrowserWebView: NSViewRepresentable {
    let session: BrowserSession
    var isActive: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeNSView(context: Context) -> BrowserContainerView {
        let container = BrowserContainerView(frame: .zero)
        container.isActive = isActive
        context.coordinator.container = container

        // Create webview for the initial tab
        if let tab = session.activeTab {
            let webView = context.coordinator.getOrCreateWebView(for: tab)
            container.setActiveWebView(webView)

            // Load initial URL if present
            if let url = tab.url {
                webView.load(URLRequest(url: url))
            }
        }

        session.controller = context.coordinator
        return container
    }

    func updateNSView(_ container: BrowserContainerView, context: Context) {
        container.isActive = isActive
        let coordinator = context.coordinator

        // Switch visible webview when active tab changes
        if let tab = session.activeTab {
            let webView = coordinator.getOrCreateWebView(for: tab)
            container.setActiveWebView(webView)

            // Consume pending navigation
            if let action = tab.pendingNavigation {
                tab.pendingNavigation = nil
                coordinator.executeNavigation(action, in: tab)
            }
        }

        // Claim focus when active
        if isActive, let webView = container.activeWebView,
           let window = webView.window, window.firstResponder !== webView {
            window.makeFirstResponder(webView)
        }
    }

    static func dismantleNSView(_ container: BrowserContainerView, coordinator: Coordinator) {
        container.isActive = false
        coordinator.cleanup()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, BrowserController {
        let session: BrowserSession
        weak var container: BrowserContainerView?
        private var webViews: [UUID: WKWebView] = [:]
        private var observations: [UUID: [NSKeyValueObservation]] = [:]

        /// JavaScript injected to capture console output
        private static let consoleScript: String = """
        (function() {
            const orig = {
                log: console.log, warn: console.warn,
                error: console.error, info: console.info
            };
            function send(level, args) {
                try {
                    window.webkit.messageHandlers.consoleCapture.postMessage({
                        level: level,
                        message: Array.from(args).map(function(a) {
                            return typeof a === 'object' ? JSON.stringify(a, null, 2) : String(a);
                        }).join(' ')
                    });
                } catch(e) {}
            }
            console.log = function() { send('log', arguments); orig.log.apply(console, arguments); };
            console.warn = function() { send('warn', arguments); orig.warn.apply(console, arguments); };
            console.error = function() { send('error', arguments); orig.error.apply(console, arguments); };
            console.info = function() { send('info', arguments); orig.info.apply(console, arguments); };
        })();
        """

        /// JavaScript injected to capture network requests via fetch/XHR monkey-patching
        private static let networkScript: String = """
        (function() {
            // Capture fetch requests
            const origFetch = window.fetch;
            window.fetch = function() {
                const url = arguments[0] instanceof Request ? arguments[0].url : String(arguments[0]);
                const method = (arguments[1] && arguments[1].method) || 'GET';
                const startTime = performance.now();
                const reqId = Math.random().toString(36).substr(2, 9);
                window.webkit.messageHandlers.networkCapture.postMessage({
                    type: 'start', id: reqId, method: method, url: url
                });
                return origFetch.apply(this, arguments).then(function(response) {
                    const duration = performance.now() - startTime;
                    window.webkit.messageHandlers.networkCapture.postMessage({
                        type: 'end', id: reqId, status: response.status,
                        statusText: response.statusText, duration: duration
                    });
                    return response;
                }).catch(function(err) {
                    window.webkit.messageHandlers.networkCapture.postMessage({
                        type: 'error', id: reqId, error: err.message
                    });
                    throw err;
                });
            };

            // Capture XMLHttpRequest
            const origXHROpen = XMLHttpRequest.prototype.open;
            const origXHRSend = XMLHttpRequest.prototype.send;
            XMLHttpRequest.prototype.open = function(method, url) {
                this._wrangle = { method: method, url: url, id: Math.random().toString(36).substr(2, 9) };
                return origXHROpen.apply(this, arguments);
            };
            XMLHttpRequest.prototype.send = function() {
                if (this._wrangle) {
                    const info = this._wrangle;
                    const startTime = performance.now();
                    window.webkit.messageHandlers.networkCapture.postMessage({
                        type: 'start', id: info.id, method: info.method, url: info.url
                    });
                    this.addEventListener('loadend', function() {
                        const duration = performance.now() - startTime;
                        window.webkit.messageHandlers.networkCapture.postMessage({
                            type: 'end', id: info.id, status: this.status,
                            statusText: this.statusText, duration: duration
                        });
                    });
                }
                return origXHRSend.apply(this, arguments);
            };
        })();
        """

        init(session: BrowserSession) {
            self.session = session
            super.init()
        }

        // MARK: - WebView Lifecycle

        func getOrCreateWebView(for tab: BrowserTab) -> WKWebView {
            if let existing = webViews[tab.id] {
                return existing
            }

            let config = WKWebViewConfiguration()
            config.processPool = session.processPool

            let userContent = WKUserContentController()
            userContent.add(WeakScriptMessageHandler(delegate: self), name: "consoleCapture")
            userContent.add(WeakScriptMessageHandler(delegate: self), name: "networkCapture")
            userContent.add(WeakScriptMessageHandler(delegate: self), name: "elementInspector")

            let consoleUserScript = WKUserScript(
                source: Self.consoleScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            userContent.addUserScript(consoleUserScript)

            let networkUserScript = WKUserScript(
                source: Self.networkScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContent.addUserScript(networkUserScript)

            config.userContentController = userContent

            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.allowsBackForwardNavigationGestures = true
            if #available(macOS 13.3, *) {
                webView.isInspectable = true
            }

            // Set up KVO observations
            let obs = setupObservations(for: webView, tab: tab)
            observations[tab.id] = obs

            webViews[tab.id] = webView
            return webView
        }

        private func setupObservations(for webView: WKWebView, tab: BrowserTab) -> [NSKeyValueObservation] {
            [
                webView.observe(\.title) { [weak tab] wv, _ in
                    Task { @MainActor in
                        tab?.title = wv.title ?? "Untitled"
                    }
                },
                webView.observe(\.url) { [weak tab] wv, _ in
                    Task { @MainActor in
                        tab?.url = wv.url
                    }
                },
                webView.observe(\.isLoading) { [weak tab] wv, _ in
                    Task { @MainActor in
                        tab?.isLoading = wv.isLoading
                    }
                },
                webView.observe(\.canGoBack) { [weak tab] wv, _ in
                    Task { @MainActor in
                        tab?.canGoBack = wv.canGoBack
                    }
                },
                webView.observe(\.canGoForward) { [weak tab] wv, _ in
                    Task { @MainActor in
                        tab?.canGoForward = wv.canGoForward
                    }
                },
                webView.observe(\.estimatedProgress) { [weak tab] wv, _ in
                    Task { @MainActor in
                        tab?.estimatedProgress = wv.estimatedProgress
                    }
                },
            ]
        }

        func removeWebView(for tabID: UUID) {
            observations[tabID]?.forEach { $0.invalidate() }
            observations.removeValue(forKey: tabID)
            let wv = webViews.removeValue(forKey: tabID)
            wv?.removeFromSuperview()
        }

        func cleanup() {
            for (tabID, _) in webViews {
                observations[tabID]?.forEach { $0.invalidate() }
            }
            observations.removeAll()
            webViews.values.forEach { $0.removeFromSuperview() }
            webViews.removeAll()
        }

        // MARK: - Navigation Execution

        func executeNavigation(_ action: NavigationAction, in tab: BrowserTab) {
            guard let webView = webViews[tab.id] else { return }
            switch action {
            case .load(let url):
                webView.load(URLRequest(url: url))
            case .goBack:
                webView.goBack()
            case .goForward:
                webView.goForward()
            case .reload:
                webView.reload()
            case .stop:
                webView.stopLoading()
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            .allow
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Favicon extraction via injected JS
            guard let tab = tab(for: webView) else { return }
            webView.evaluateJavaScript("""
                (function() {
                    var link = document.querySelector('link[rel~="icon"]');
                    return link ? link.href : null;
                })();
            """) { [weak self] result, _ in
                guard let urlString = result as? String, let url = URL(string: urlString) else { return }
                Task { @MainActor [weak self] in
                    _ = self // Keep reference
                    self?.loadFavicon(from: url, for: tab)
                }
            }
        }

        private func loadFavicon(from url: URL, for tab: BrowserTab) {
            Task.detached {
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      let image = NSImage(data: data) else { return }
                await MainActor.run {
                    tab.favicon = image
                }
            }
        }

        // MARK: - WKUIDelegate

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Open target=_blank links in a new internal tab
            if let url = navigationAction.request.url {
                Task { @MainActor in
                    session.addTab(url: url)
                }
            }
            return nil
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            Task { @MainActor in
                guard let body = message.body as? [String: Any] else { return }

                switch message.name {
                case "consoleCapture":
                    handleConsoleMessage(body)
                case "networkCapture":
                    handleNetworkMessage(body)
                case "elementInspector":
                    handleElementMessage(body)
                default:
                    break
                }
            }
        }

        private func handleConsoleMessage(_ body: [String: Any]) {
            guard let levelStr = body["level"] as? String,
                  let level = ConsoleMessage.Level(rawValue: levelStr),
                  let text = body["message"] as? String,
                  let tab = session.activeTab else { return }

            let message = ConsoleMessage(level: level, text: text, timestamp: Date())
            tab.consoleMessages.append(message)
        }

        private func handleNetworkMessage(_ body: [String: Any]) {
            // Network messages are handled by NetworkInspectorView's state
            // Posted via NotificationCenter for decoupling
            NotificationCenter.default.post(
                name: .browserNetworkEvent,
                object: nil,
                userInfo: body
            )
        }

        private func handleElementMessage(_ body: [String: Any]) {
            NotificationCenter.default.post(
                name: .browserElementEvent,
                object: nil,
                userInfo: body
            )
        }

        // MARK: - BrowserController

        func loadURL(_ url: URL, in tab: BrowserTab) {
            webViews[tab.id]?.load(URLRequest(url: url))
        }

        func goBack(in tab: BrowserTab) {
            webViews[tab.id]?.goBack()
        }

        func goForward(in tab: BrowserTab) {
            webViews[tab.id]?.goForward()
        }

        func reload(in tab: BrowserTab) {
            webViews[tab.id]?.reload()
        }

        func stop(in tab: BrowserTab) {
            webViews[tab.id]?.stopLoading()
        }

        func getCookies() async -> [HTTPCookie] {
            await withCheckedContinuation { continuation in
                WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                    continuation.resume(returning: cookies)
                }
            }
        }

        func deleteCookie(_ cookie: HTTPCookie) async {
            await withCheckedContinuation { continuation in
                WKWebsiteDataStore.default().httpCookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }

        func setCookie(_ cookie: HTTPCookie) async {
            await withCheckedContinuation { continuation in
                WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie) {
                    continuation.resume()
                }
            }
        }

        func evaluateJavaScript(_ script: String, in tab: BrowserTab) async throws -> Any? {
            guard let webView = webViews[tab.id] else { return nil }
            return try await webView.evaluateJavaScript(script)
        }

        func webView(for tab: BrowserTab) -> WKWebView? {
            webViews[tab.id]
        }

        // MARK: - Helpers

        private func tab(for webView: WKWebView) -> BrowserTab? {
            guard let entry = webViews.first(where: { $0.value === webView }) else { return nil }
            return session.tabs.first(where: { $0.id == entry.key })
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let browserNetworkEvent = Notification.Name("browserNetworkEvent")
    static let browserElementEvent = Notification.Name("browserElementEvent")
}
