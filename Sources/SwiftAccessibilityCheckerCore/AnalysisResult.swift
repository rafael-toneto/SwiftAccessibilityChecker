import Foundation

/// Files or directories that could not be inspected. These are execution failures,
/// separate from accessibility findings, so a partial scan cannot look clean.
public struct AnalysisIssue: Codable, Equatable, Sendable {
    public let filePath: String
    public let message: String
    public let stage: String

    public init(filePath: String, message: String, stage: String) {
        self.filePath = filePath
        self.message = message
        self.stage = stage
    }
}

public struct AnalysisSummary: Codable, Equatable, Sendable {
    public let totalIssues: Int
    public let bySeverity: [String: Int]
    public let byRule: [String: Int]

    public init(diagnostics: [Diagnostic]) {
        var severityCounts = Dictionary(
            uniqueKeysWithValues: DiagnosticSeverity.allCases.map { ($0.rawValue, 0) }
        )
        diagnostics.forEach { severityCounts[$0.severity.rawValue, default: 0] += 1 }

        totalIssues = diagnostics.count
        bySeverity = severityCounts
        byRule = Dictionary(grouping: diagnostics, by: \Diagnostic.ruleIdentifier)
            .mapValues(\.count)
    }
}

public struct AnalysisResult: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = "1.1"
    public static let toolName = "Swift Accessibility Checker"

    public let schemaVersion: String
    public let tool: String
    public let generatedAt: Date
    public let inputPaths: [String]
    public let analyzedFiles: [String]
    public let summary: AnalysisSummary
    public let diagnostics: [Diagnostic]
    /// Absent in legacy reports and complete scans; decoding schema 1.0 still works.
    public let analysisIssues: [AnalysisIssue]?

    public init(
        generatedAt: Date = Date(),
        inputPaths: [String],
        analyzedFiles: [String],
        diagnostics: [Diagnostic],
        analysisIssues: [AnalysisIssue] = []
    ) {
        let sortedDiagnostics = diagnostics.sorted {
            ($0.filePath, $0.line, $0.column, $0.ruleIdentifier)
                < ($1.filePath, $1.line, $1.column, $1.ruleIdentifier)
        }

        self.schemaVersion = Self.currentSchemaVersion
        self.tool = Self.toolName
        self.generatedAt = generatedAt
        self.inputPaths = inputPaths.sorted()
        self.analyzedFiles = analyzedFiles.sorted()
        self.summary = AnalysisSummary(diagnostics: sortedDiagnostics)
        self.diagnostics = sortedDiagnostics
        self.analysisIssues = analysisIssues.isEmpty ? nil : analysisIssues.sorted {
            ($0.filePath, $0.stage, $0.message) < ($1.filePath, $1.stage, $1.message)
        }
    }
}
