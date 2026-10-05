import Foundation
import SwiftAccessibilityCheckerCore

public struct ProjectAnalysisRun: Sendable {
    public let result: AnalysisResult
    public let discoveredFiles: [URL]
    public let invalidInputPaths: [String]

    public init(result: AnalysisResult, discoveredFiles: [URL], invalidInputPaths: [String]) {
        self.result = result
        self.discoveredFiles = discoveredFiles
        self.invalidInputPaths = invalidInputPaths
    }
}

/// Discovers and analyzes Swift files once for every report format and interface.
public struct ProjectAnalysisRunner: Sendable {
    public init() {}

    public func run(inputPaths: [String]) -> ProjectAnalysisRun {
        let discoverer = SwiftFileDiscoverer()
        var discoveredFilesByPath: [String: URL] = [:]
        var analysisIssues: [AnalysisIssue] = []
        var invalidInputPaths: [String] = []

        for inputPath in inputPaths {
            do {
                let discovery = try discoverer.discover(at: inputPath)
                discovery.files.forEach { file in
                    discoveredFilesByPath[file.resolvingSymlinksInPath().path] = file
                }
                analysisIssues.append(contentsOf: discovery.issues.map {
                    AnalysisIssue(filePath: $0.filePath, message: $0.message, stage: "discovery")
                })
            } catch {
                invalidInputPaths.append(inputPath)
                analysisIssues.append(AnalysisIssue(
                    filePath: inputPath, message: error.localizedDescription, stage: "discovery"
                ))
            }
        }

        let analyzer = SwiftSourceAnalyzer()
        var analyzedFiles: [String] = []
        var diagnostics: [Diagnostic] = []
        let discoveredFiles = discoveredFilesByPath.values.sorted { $0.path < $1.path }

        for file in discoveredFiles {
            do {
                let source = try String(contentsOf: file, encoding: .utf8)
                diagnostics.append(contentsOf: analyzer.analyze(source: source, filePath: file.path))
                analyzedFiles.append(file.path)
            } catch {
                analysisIssues.append(AnalysisIssue(
                    filePath: file.path, message: error.localizedDescription, stage: "read"
                ))
            }
        }

        return ProjectAnalysisRun(
            result: AnalysisResult(
                inputPaths: inputPaths,
                analyzedFiles: analyzedFiles,
                diagnostics: diagnostics,
                analysisIssues: analysisIssues
            ),
            discoveredFiles: discoveredFiles,
            invalidInputPaths: invalidInputPaths
        )
    }
}
