import Foundation
import Testing
@testable import Wrangle

@MainActor
@Suite("EditorDocument")
struct EditorDocumentTests {

    // MARK: - Helpers

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
    }

    // MARK: - Init

    @Test("Init with no URL is dirty and Untitled")
    func initNoURL() {
        let doc = EditorDocument()
        #expect(doc.isDirty == true)
        #expect(doc.fileName == "Untitled")
    }

    @Test("Init with URL is not dirty and has correct fileName")
    func initWithURL() {
        let url = URL(fileURLWithPath: "/tmp/test-file.md")
        let doc = EditorDocument(fileURL: url)
        #expect(doc.isDirty == false)
        #expect(doc.fileName == "test-file.md")
    }

    // MARK: - FileType

    @Test("fileType detects from URL")
    func fileTypeFromURL() {
        let url = URL(fileURLWithPath: "/tmp/claude.md")
        let doc = EditorDocument(fileURL: url)
        #expect(doc.fileType == .claudeMD)
    }

    @Test("fileType falls back to content detection")
    func fileTypeFromContent() {
        let doc = EditorDocument(content: "<tools>something</tools>")
        #expect(doc.fileType == .systemPrompt)
    }

    @Test("fileType defaults to plainText")
    func fileTypeDefault() {
        let doc = EditorDocument()
        #expect(doc.fileType == .plainText)
    }

    // MARK: - Load

    @Test("load() reads file content and clears dirty")
    func loadFile() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        try "Hello, Wrangle!".write(to: url, atomically: true, encoding: .utf8)

        let doc = EditorDocument(fileURL: url)
        try doc.load()

        #expect(doc.content == "Hello, Wrangle!")
        #expect(doc.isDirty == false)
    }

    @Test("load() with no URL is a no-op")
    func loadNoURL() throws {
        let doc = EditorDocument()
        try doc.load()
        #expect(doc.content == "")
    }

    // MARK: - Save

    @Test("save() persists content and clears dirty")
    func saveFile() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let doc = EditorDocument(fileURL: url, content: "saved content")
        try doc.save()

        let onDisk = try String(contentsOf: url, encoding: .utf8)
        #expect(onDisk == "saved content")
        #expect(doc.isDirty == false)
    }

    @Test("save() with no URL throws")
    func saveNoURL() {
        let doc = EditorDocument()
        #expect(throws: CocoaError.self) {
            try doc.save()
        }
    }

    // MARK: - Save As

    @Test("saveAs changes URL and persists")
    func saveAs() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let doc = EditorDocument(content: "new content")
        try doc.saveAs(to: url)

        #expect(doc.fileURL == url)
        let onDisk = try String(contentsOf: url, encoding: .utf8)
        #expect(onDisk == "new content")
    }

    // MARK: - Mark Dirty

    @Test("markDirty when content differs from lastSavedContent")
    func markDirtyChanged() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let doc = EditorDocument(fileURL: url, content: "original")
        doc.content = "modified"
        doc.markDirty()
        #expect(doc.isDirty == true)
    }

    @Test("markDirty stays clean when content matches lastSavedContent")
    func markDirtyUnchanged() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let doc = EditorDocument(fileURL: url, content: "same")
        doc.content = "same"
        doc.markDirty()
        #expect(doc.isDirty == false)
    }

    // MARK: - Cached Stats

    @Test("updateCachedStats computes correct counts")
    func cachedStats() {
        let doc = EditorDocument(content: "Hello world\nSecond line\nThird line")
        doc.updateCachedStats()

        #expect(doc.cachedLineCount == 3)
        #expect(doc.cachedCharCount == 34)
        #expect(doc.cachedTokenCount > 0)
    }

    @Test("Empty doc has 1 line, 0 chars, 0 tokens")
    func emptyDocStats() {
        let doc = EditorDocument()
        doc.updateCachedStats()

        #expect(doc.cachedLineCount == 1)
        #expect(doc.cachedCharCount == 0)
        #expect(doc.cachedTokenCount == 0)
    }
}
