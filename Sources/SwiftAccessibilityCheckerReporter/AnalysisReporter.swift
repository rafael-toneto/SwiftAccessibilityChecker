import SwiftAccessibilityCheckerCore

public protocol AnalysisReporter: Sendable {
    func render(_ result: AnalysisResult) throws -> String
}
