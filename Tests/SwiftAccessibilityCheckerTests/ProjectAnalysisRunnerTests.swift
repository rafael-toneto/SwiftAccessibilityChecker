import Foundation
import SwiftAccessibilityCheckerAnalyzer
import Testing

@Suite("Project analysis shared by CLI and GUI")
struct ProjectAnalysisRunnerTests {
    @Test("Analyzes overlapping inputs once and records invalid paths")
    func analyzesOverlappingInputs() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SAC-ProjectAnalysisRunner-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sourceFile = directory.appendingPathComponent("Toolbar.swift")
        try """
        import SwiftUI
        struct Toolbar: View {
            var body: some View {
                Button(action: {}) { Image(systemName: "trash") }
            }
        }
        """.write(to: sourceFile, atomically: true, encoding: .utf8)
        let missingPath = directory.appendingPathComponent("Missing.swift").path

        let run = ProjectAnalysisRunner().run(inputPaths: [directory.path, sourceFile.path, missingPath])

        #expect(run.discoveredFiles.map(\.path) == [sourceFile.path])
        #expect(run.result.analyzedFiles == [sourceFile.path])
        #expect(run.result.diagnostics.map(\.ruleIdentifier) == ["SAC001"])
        #expect(run.invalidInputPaths == [missingPath])
        #expect(run.result.analysisIssues?.count == 1)
    }
}
