import Foundation
import SwiftAccessibilityCheckerCore
import Testing

@Suite("Swift file discovery")
struct SwiftFileDiscovererTests {
    @Test("Discovers recursively in deterministic order and ignores build directories")
    func discoversRecursivelyInDeterministicOrderAndIgnoresBuildDirectories() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let nested = root.appendingPathComponent("Nested", isDirectory: true)
        let ignored = root.appendingPathComponent(".build", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: ignored, withIntermediateDirectories: true)

        try "let z = 1".write(
            to: root.appendingPathComponent("Z.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "let a = 1".write(
            to: root.appendingPathComponent("A.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "let b = 1".write(
            to: nested.appendingPathComponent("B.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "ignored".write(
            to: ignored.appendingPathComponent("Ignored.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "not swift".write(
            to: root.appendingPathComponent("Notes.txt"),
            atomically: true,
            encoding: .utf8
        )

        let result = try SwiftFileDiscoverer().discover(at: root.path)
        let paths = result.files.map(\.path)

        #expect(paths == paths.sorted())
        #expect(result.files.map(\.lastPathComponent) == ["A.swift", "B.swift", "Z.swift"])
        #expect(result.issues.isEmpty)
    }

    @Test("Rejects a non-Swift input file")
    func rejectsNonSwiftInputFile() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: file) }
        try "text".write(to: file, atomically: true, encoding: .utf8)

        do {
            _ = try SwiftFileDiscoverer().discover(at: file.path)
            Issue.record("Expected discovery to reject a non-Swift file")
        } catch let error as SwiftFileDiscoveryError {
            #expect(error == .inputIsNotSwiftFile(file.path))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
