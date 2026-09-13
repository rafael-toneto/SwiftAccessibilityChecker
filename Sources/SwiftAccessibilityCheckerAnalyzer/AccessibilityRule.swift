import SwiftAccessibilityCheckerCore
import SwiftSyntax

public protocol AccessibilityRule {
    var definition: AccessibilityRuleDefinition { get }

    func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic]
}

public extension AccessibilityRule {
    var identifier: String { definition.identifier }
}
