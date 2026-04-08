//
//  BrowserController.swift
//  Wrangle
//

import Foundation
import WebKit

@MainActor
protocol BrowserController: AnyObject {
    func loadURL(_ url: URL, in tab: BrowserTab)
    func goBack(in tab: BrowserTab)
    func goForward(in tab: BrowserTab)
    func reload(in tab: BrowserTab)
    func stop(in tab: BrowserTab)
    func getCookies() async -> [HTTPCookie]
    func deleteCookie(_ cookie: HTTPCookie) async
    func setCookie(_ cookie: HTTPCookie) async
    func evaluateJavaScript(_ script: String, in tab: BrowserTab) async throws -> Any?
    func webView(for tab: BrowserTab) -> WKWebView?
}
