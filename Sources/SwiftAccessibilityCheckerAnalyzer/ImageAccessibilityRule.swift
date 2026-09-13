import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct ImageAccessibilityRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.imageAccessibility

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = ImageAccessibilityVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class ImageAccessibilityVisitor: SyntaxVisitor {
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
        guard SyntaxInspection.isSwiftUIConstructor(node, named: "Image") else {
            return .visitChildren
        }

        guard
            !node.arguments.contains(where: { $0.label?.text == "decorative" }),
            !SyntaxInspection.hasAncestorConstructor(named: "Button", from: node),
            !SyntaxInspection.hasAncestorConstructor(named: "Label", from: node),
            let expression = SyntaxInspection.outermostChainedExpression(containing: node),
            !SyntaxInspection.containsActiveModifier(
                named: "accessibilityLabel",
                in: expression
            ),
            !SyntaxInspection.containsActiveModifier(
                named: "accessibilityRepresentation",
                in: expression
            ),
            !isExplicitlyHiddenFromAccessibility(expression)
        else {
            return .visitChildren
        }

        let location = locationConverter.location(
            for: node.calledExpression.positionAfterSkippingLeadingTrivia
        )

        diagnostics.append(
            Diagnostic(
                rule: rule,
                filePath: filePath,
                line: location.line,
                column: location.column
            )
        )

        return .visitChildren
    }

    private func isExplicitlyHiddenFromAccessibility(_ expression: ExprSyntax) -> Bool {
        SyntaxInspection.modifierCalls(in: expression).contains { call in
            guard
                SyntaxInspection.modifierName(of: call) == "accessibilityHidden",
                let hiddenArgument = call.arguments.first,
                SyntaxInspection.booleanLiteral(in: hiddenArgument.expression) == true,
                SyntaxInspection.isModifierEnabled(call)
            else {
                return false
            }
            return true
        }
    }
}
