import SwiftUI
import Testing
@testable import Wrangle

@MainActor
@Suite("TokenCounter")
struct TokenCounterTests {

    @Test("Empty string returns 0")
    func emptyString() {
        #expect(TokenCounter.count("") == 0)
    }

    @Test("Single word returns at least 1")
    func singleWord() {
        #expect(TokenCounter.count("hello") >= 1)
    }

    @Test("More words produce more tokens")
    func monotonicity() {
        let short = TokenCounter.count("hello world")
        let long = TokenCounter.count("hello world this is a longer sentence with many words")
        #expect(long > short)
    }

    @Test("Special characters increase token count")
    func specialCharacters() {
        let plain = TokenCounter.count("function name value return")
        let special = TokenCounter.count("function() { name: value; return }")
        #expect(special > plain)
    }

    @Test("formattedCount formats correctly", arguments: [
        (999, "999"),
        (1000, "1.0K"),
        (3200, "3.2K"),
        (15000, "15.0K"),
        (0, "0"),
    ] as [(Int, String)])
    func formattedCount(count: Int, expected: String) {
        #expect(TokenCounter.formattedCount(count) == expected)
    }

    @Test("colorForCount returns correct color at boundaries", arguments: [
        (0, "green"),
        (3999, "green"),
        (4000, "yellow"),
        (7999, "yellow"),
        (8000, "orange"),
        (31999, "orange"),
        (32000, "red"),
        (100000, "red"),
    ] as [(Int, String)])
    func colorForCount(count: Int, expectedColor: String) {
        let color = TokenCounter.colorForCount(count)
        switch expectedColor {
        case "green": #expect(color == .green)
        case "yellow": #expect(color == .yellow)
        case "orange": #expect(color == .orange)
        case "red": #expect(color == .red)
        default: Issue.record("Unknown color: \(expectedColor)")
        }
    }
}
