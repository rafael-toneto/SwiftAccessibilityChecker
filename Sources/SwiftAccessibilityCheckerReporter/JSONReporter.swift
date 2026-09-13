import Foundation
import SwiftAccessibilityCheckerCore

public struct JSONReporter: AnalysisReporter {
    public init() {}

    public func render(_ result: AnalysisResult) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(result)
        guard let output = String(data: data, encoding: .utf8) else {
            throw JSONReporterError.invalidUTF8Output
        }
        return output
    }
}

public enum JSONReporterError: LocalizedError {
    case invalidUTF8Output

    public var errorDescription: String? {
        "The generated JSON could not be represented as UTF-8"
    }
}
