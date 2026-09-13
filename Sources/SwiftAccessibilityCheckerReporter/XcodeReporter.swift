import SwiftAccessibilityCheckerCore

public struct XcodeReporter: AnalysisReporter {
    public init() {}

    public func render(_ result: AnalysisResult) -> String {
        result.diagnostics
            .map(XcodeDiagnosticFormatter.format)
            .joined(separator: "\n")
    }
}

public enum XcodeDiagnosticFormatter {
    public static func format(_ diagnostic: Diagnostic) -> String {
        // Static findings remain warnings because they indicate review risks rather
        // than certifying a definitive accessibility violation.
        "\(diagnostic.filePath):\(diagnostic.line):\(diagnostic.column): "
            + "warning: \(diagnostic.description) "
            + "[\(diagnostic.ruleIdentifier)] [\(diagnostic.severity.rawValue)]"
    }
}
