import Foundation
import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct EmptyAccessibilityMetadataRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.emptyAccessibilityMetadata

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = EmptyAccessibilityMetadataVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class EmptyAccessibilityMetadataVisitor: SyntaxVisitor {
    private static let metadataNames: [String: String] = [
        "accessibilityHint": "hint",
        "accessibilityLabel": "label",
        "accessibilityValue": "value"
    ]

    private let filePath: String
    private let locationConverter: SourceLocationConverter
    private let rule: AccessibilityRuleDefinition

    private(set) var diagnostics: [Diagnostic] = []

    init(
        filePath: String,
        locationConverter: SourceLocationConverter,
        rule: AccessibilityRuleDefinition
    ) {
        self.filePath = filePath
        self.locationConverter = locationConverter
        self.rule = rule
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            let modifierName = SyntaxInspection.modifierName(of: node),
            let metadataName = Self.metadataNames[modifierName],
            let valueArgument = node.arguments.first,
            let value = SyntaxInspection.literalText(in: valueArgument.expression),
            value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            SyntaxInspection.isModifierEnabled(node),
            let member = node.calledExpression.as(MemberAccessExprSyntax.self)
        else {
            return .visitChildren
        }

        let location = locationConverter.location(
            for: member.period.positionAfterSkippingLeadingTrivia
        )

        diagnostics.append(
            Diagnostic(
                rule: rule,
                description: "Accessibility \(metadataName) must not be empty",
                filePath: filePath,
                line: location.line,
                column: location.column
            )
        )

        return .visitChildren
    }
}
