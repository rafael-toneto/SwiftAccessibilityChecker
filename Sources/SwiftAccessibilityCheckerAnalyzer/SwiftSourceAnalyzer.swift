import Foundation
import SwiftAccessibilityCheckerCore
import SwiftParser
import SwiftSyntax

public struct SwiftSourceAnalyzer {
    private let rules: [any AccessibilityRule]

    public init(
        rules: [any AccessibilityRule] = AccessibilityRuleCatalog.defaultRules
    ) {
        self.rules = rules
    }

    public func analyze(source: String, filePath: String) -> [Diagnostic] {
        let syntax = Parser.parse(source: source)
        let locationConverter = SourceLocationConverter(
            fileName: filePath,
            tree: syntax
        )

        let diagnostics = rules.flatMap { rule in
            rule.analyze(
                syntax: syntax,
                filePath: filePath,
                locationConverter: locationConverter
            )
        }

        return diagnostics.map { diagnostic in
            diagnostic.addingSourceExcerpt(
                sourceExcerpt(at: diagnostic.line, in: source)
            )
        }
    }

    private func sourceExcerpt(at line: Int, in source: String) -> String? {
        guard line > 0 else { return nil }

        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.indices.contains(line - 1) else { return nil }

        let excerpt = String(lines[line - 1])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return excerpt.isEmpty ? nil : excerpt
    }
}
