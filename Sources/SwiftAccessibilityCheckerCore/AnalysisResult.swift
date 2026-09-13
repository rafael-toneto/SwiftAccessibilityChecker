import Foundation

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
    public static let currentSchemaVersion = "1.0"
    public static let toolName = "Swift Accessibility Checker"

    public let schemaVersion: String
    public let tool: String
    public let generatedAt: Date
    public let inputPaths: [String]
    public let analyzedFiles: [String]
    public let summary: AnalysisSummary
    public let diagnostics: [Diagnostic]

    public init(
        generatedAt: Date = Date(),
        inputPaths: [String],
        analyzedFiles: [String],
        diagnostics: [Diagnostic]
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
    }
}
