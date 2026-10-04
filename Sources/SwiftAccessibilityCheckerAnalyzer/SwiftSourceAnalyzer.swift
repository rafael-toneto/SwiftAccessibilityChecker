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

        let lines = source.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
        return diagnostics.map { diagnostic in
            let index = diagnostic.line - 1
            guard lines.indices.contains(index) else { return diagnostic }
            let excerpt = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            let context = (max(0, index - 2)...min(lines.count - 1, index + 2)).map {
                SourceContextLine(line: $0 + 1, text: lines[$0])
            }
            return diagnostic.addingSourceExcerpt(excerpt.isEmpty ? nil : excerpt)
                .addingSourceContext(context)
        }
    }
}
