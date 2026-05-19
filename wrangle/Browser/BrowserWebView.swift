//
//  BrowserWebView.swift
//  Wrangle
//

import SwiftUI
import SwiftData
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
    var modelContext: ModelContext? = nil
    weak var appState: AppState? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, modelContext: modelContext, appState: appState)
    }

    func makeNSView(context: Context) -> BrowserContainerView {
        let container = BrowserContainerView(frame: .zero)
        container.isActive = isActive
        container.isHidden = !isActive
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
        container.isHidden = !isActive
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
        let modelContext: ModelContext?
        weak var appState: AppState?
        weak var container: BrowserContainerView?
        private var webViews: [UUID: WKWebView] = [:]
        private var observations: [UUID: [NSKeyValueObservation]] = [:]
        private var appearanceObservation: NSKeyValueObservation?

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

        init(session: BrowserSession, modelContext: ModelContext?, appState: AppState?) {
            self.session = session
            self.modelContext = modelContext
            self.appState = appState
            super.init()

            // Keep every managed webview in sync with the app's current
            // appearance whenever macOS or the user toggles dark mode.
            appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let appearance = NSApp.effectiveAppearance
                    for webView in self.webViews.values {
                        webView.appearance = appearance
                    }
                }
            }
        }

        // MARK: - WebView Lifecycle

        func getOrCreateWebView(for tab: BrowserTab) -> WKWebView {
            if let existing = webViews[tab.id] {
                return existing
            }

            let config = WKWebViewConfiguration()

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

            // Private/incognito: use a non-persistent data store so cookies,
            // cache, and localStorage are discarded at session teardown.
            if session.isPrivate {
                config.websiteDataStore = .nonPersistent()
            }

            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.allowsBackForwardNavigationGestures = true
            if #available(macOS 13.3, *) {
                webView.isInspectable = true
            }
            if let customUA = BrowserUserAgent.resolved() {
                webView.customUserAgent = customUA
            }

            // Match the app's current appearance so web content picks up the
            // `prefers-color-scheme` media query correctly (dark mode in-app →
            // dark mode web content for sites that honor the hint).
            webView.appearance = NSApp.effectiveAppearance

            // Set up KVO observations
            let obs = setupObservations(for: webView, tab: tab)
            observations[tab.id] = obs

            webViews[tab.id] = webView
            return webView
        }

        private func setupObservations(for webView: WKWebView, tab: BrowserTab) -> [NSKeyValueObservation] {
            let tab = tab
            return [
                webView.observe(\.title) { wv, _ in
                    Task { @MainActor in
                        tab.title = wv.title ?? "Untitled"
                    }
                },
                webView.observe(\.url) { wv, _ in
                    Task { @MainActor in
                        tab.url = wv.url
                    }
                },
                webView.observe(\.isLoading) { wv, _ in
                    Task { @MainActor in
                        tab.isLoading = wv.isLoading
                    }
                },
                webView.observe(\.canGoBack) { wv, _ in
                    Task { @MainActor in
                        tab.canGoBack = wv.canGoBack
                    }
                },
                webView.observe(\.canGoForward) { wv, _ in
                    Task { @MainActor in
                        tab.canGoForward = wv.canGoForward
                    }
                },
                webView.observe(\.estimatedProgress) { wv, _ in
                    Task { @MainActor in
                        tab.estimatedProgress = wv.estimatedProgress
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
            appearanceObservation?.invalidate()
            appearanceObservation = nil
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
            case .reloadFromOrigin:
                webView.reloadFromOrigin()
            case .stop:
                webView.stopLoading()
            case .zoomIn:
                webView.pageZoom = min(webView.pageZoom + 0.1, 3.0)
            case .zoomOut:
                webView.pageZoom = max(webView.pageZoom - 0.1, 0.25)
            case .zoomReset:
                webView.pageZoom = 1.0
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            .allow
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            // Divert non-renderable MIME types (e.g., .zip, .dmg) into downloads.
            if !navigationResponse.canShowMIMEType {
                return .download
            }
            return .allow
        }

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            DownloadManager.shared.modelContext = modelContext
            DownloadManager.shared.begin(download, suggestedURL: navigationAction.request.url)
        }

        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            DownloadManager.shared.modelContext = modelContext
            DownloadManager.shared.begin(download, suggestedURL: navigationResponse.response.url)
        }

        nonisolated func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            // Capture server trust for padlock display, then let the system do default evaluation.
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let trust = challenge.protectionSpace.serverTrust {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if let tab = self.tab(for: webView) {
                        tab.serverTrust = trust
                    }
                }
            }
            return (.performDefaultHandling, nil)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Reset security state at the start of a new navigation.
            guard let tab = tab(for: webView) else { return }
            tab.serverTrust = nil
            if let url = webView.url ?? (navigation.value(forKey: "request") as? URLRequest)?.url {
                tab.securityState = Self.securityState(for: url, trust: nil)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            guard let tab = tab(for: webView) else { return }
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain,
               (nsError.code == NSURLErrorServerCertificateUntrusted
                || nsError.code == NSURLErrorServerCertificateHasBadDate
                || nsError.code == NSURLErrorServerCertificateNotYetValid
                || nsError.code == NSURLErrorServerCertificateHasUnknownRoot
                || nsError.code == NSURLErrorSecureConnectionFailed) {
                tab.securityState = .invalid
            }
        }

        static func securityState(for url: URL, trust: SecTrust?) -> SecurityState {
            let scheme = url.scheme?.lowercased()
            switch scheme {
            case "https": return .secure
            case "http": return .insecure
            case "file", "about": return .fileLocal
            default: return .unknown
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let tab = tab(for: webView) else { return }

            // Update security state from the finished URL (may have redirected).
            if let url = webView.url {
                tab.securityState = Self.securityState(for: url, trust: tab.serverTrust)
            }

            // Record to history unless this is a private session.
            if !session.isPrivate, let url = webView.url, let context = modelContext {
                let store = HistoryStore(context: context)
                let snapshotTitle = tab.title
                let snapshotFavicon = tab.favicon
                let snapshotProjectID = session.projectID
                store.record(
                    url: url,
                    title: snapshotTitle,
                    favicon: snapshotFavicon,
                    projectID: snapshotProjectID
                )
            }

            // Use cached favicon immediately if we already have one for this host.
            if let pageURL = webView.url, let cached = FaviconCache.shared.cached(for: pageURL) {
                tab.favicon = cached
            }

            // Ask the page for its icon link; FaviconCache dedupes per host.
            webView.evaluateJavaScript("""
                (function() {
                    var link = document.querySelector('link[rel~="icon"]');
                    return link ? link.href : null;
                })();
            """) { [weak self] result, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let linkHref: URL?
                    if let urlString = result as? String {
                        linkHref = URL(string: urlString)
                    } else {
                        linkHref = nil
                    }
                    await self.loadFavicon(pageURL: webView.url, linkHref: linkHref, for: tab)
                }
            }
        }

        private func loadFavicon(pageURL: URL?, linkHref: URL?, for tab: BrowserTab) async {
            guard let pageURL else { return }
            if let cached = FaviconCache.shared.cached(for: pageURL) {
                tab.favicon = cached
                return
            }
            // Fall back to `/favicon.ico` off the page origin if page didn't declare one.
            let href = linkHref ?? URL(string: "/favicon.ico", relativeTo: pageURL)?.absoluteURL
            guard let href else { return }
            if let image = await FaviconCache.shared.favicon(for: pageURL, linkHref: href) {
                tab.favicon = image
            }
        }

        // MARK: - WKUIDelegate

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Open target=_blank links as a new workspace-level browser tab,
            // inheriting the private/non-private mode of this session.
            if let url = navigationAction.request.url {
                let isPrivate = session.isPrivate
                Task { @MainActor [weak self] in
                    self?.appState?.openBrowser(url: url, isPrivate: isPrivate)
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
