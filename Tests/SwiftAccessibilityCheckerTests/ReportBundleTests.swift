import Foundation
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter
import Testing

@Suite("Report bundles and analysis coverage")
struct ReportBundleTests {
    @Test("Writes all formats from one scan and replaces stale findings")
    func bundleLifecycle() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let diagnostics = SwiftSourceAnalyzer().analyze(
            source: "Text(\"Olá\").font(.system(size: 12))", filePath: "/project/View.swift"
        )
        let result = AnalysisResult(
            generatedAt: Date(timeIntervalSince1970: 0), inputPaths: ["/project"],
            analyzedFiles: ["/project/View.swift"], diagnostics: diagnostics
        )
        let html = try ReportBundleWriter().write(result, to: directory)
        #expect(html.lastPathComponent == "report.html")
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: directory.path))
            == Set(ReportBundleWriter.fileNames))
        let json = try Data(contentsOf: directory.appendingPathComponent("report.json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        #expect(try decoder.decode(AnalysisResult.self, from: json) == result)
        #expect(try String(contentsOf: directory.appendingPathComponent("warnings.txt"), encoding: .utf8)
            .contains("SAC003"))

        let clean = AnalysisResult(inputPaths: ["/project"], analyzedFiles: ["/project/View.swift"], diagnostics: [])
        try ReportBundleWriter().write(clean, to: directory)
        #expect(try String(contentsOf: directory.appendingPathComponent("warnings.txt"), encoding: .utf8).isEmpty)
        let updated = try Data(contentsOf: directory.appendingPathComponent("report.json"))
        #expect(try decoder.decode(AnalysisResult.self, from: updated).diagnostics.isEmpty)
    }

    @Test("Round-trips partial coverage separately from accessibility findings")
    func partialCoverage() throws {
        let result = AnalysisResult(inputPaths: ["/project"], analyzedFiles: ["/project/A.swift"], diagnostics: [],
            analysisIssues: [AnalysisIssue(filePath: "/project/B.swift", message: "Unreadable UTF-8", stage: "read")])
        let output = try JSONReporter().render(result)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnalysisResult.self, from: Data(output.utf8))
        #expect(decoded.summary.totalIssues == 0)
        #expect(decoded.analysisIssues?.count == 1)
        #expect(decoded.analysisIssues?.first?.filePath == "/project/B.swift")
    }

    @Test("Legacy JSON remains readable without context or coverage fields")
    func legacyJSON() throws {
        let result = AnalysisResult(inputPaths: ["A.swift"], analyzedFiles: ["A.swift"], diagnostics: [])
        let legacy = try JSONReporter().render(result).replacingOccurrences(of: "\"1.1\"", with: "\"1.0\"")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AnalysisResult.self, from: Data(legacy.utf8))
        #expect(decoded.schemaVersion == "1.0")
        #expect(decoded.analysisIssues == nil)
    }

    @Test("Context retains real line numbers, indentation and CRLF positions")
    func contextLines() throws {
        for separator in ["\n", "\r\n"] {
            let source = ["import SwiftUI", "", "Text(\"Olá\")", "    .font(.system(size: 12))", "// fim"].joined(separator: separator)
            let issue = try #require(SwiftSourceAnalyzer().analyze(source: source, filePath: "View.swift").first)
            #expect(issue.line == 4)
            #expect(issue.sourceExcerpt == ".font(.system(size: 12))")
            #expect(issue.sourceContext?.map(\.line) == [2, 3, 4, 5])
            #expect(issue.sourceContext?.first(where: { $0.line == 4 })?.text == "    .font(.system(size: 12))")
        }
    }

    @Test("Report destination symlinks cannot replace another file")
    func symbolicLinkDestination() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("View.swift")
        try Data("original".utf8).write(to: source)
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("report.html"), withDestinationURL: source)
        let result = AnalysisResult(inputPaths: [], analyzedFiles: [], diagnostics: [])
        #expect(throws: ReportBundleError.self) {
            try ReportBundleWriter().write(result, to: root)
        }
        #expect(try String(contentsOf: source, encoding: .utf8) == "original")
    }
}
