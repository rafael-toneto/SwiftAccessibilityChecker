import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct HiddenInteractiveControlRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.hiddenInteractiveControl

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = HiddenInteractiveControlVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class HiddenInteractiveControlVisitor: SyntaxVisitor {
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
            SyntaxInspection.modifierName(of: node) == "accessibilityHidden",
            let hiddenArgument = node.arguments.first,
            SyntaxInspection.booleanLiteral(in: hiddenArgument.expression) == true,
            SyntaxInspection.isModifierEnabled(node),
            let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            let hiddenView = member.base,
            containsInteractiveControl(in: hiddenView)
        else {
            return .visitChildren
        }

        let location = locationConverter.location(
            for: member.period.positionAfterSkippingLeadingTrivia
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

    private func containsInteractiveControl(in expression: ExprSyntax) -> Bool {
        let visitor = InteractiveControlPresenceVisitor()
        visitor.walk(expression)
        return visitor.foundControl
    }
}

private final class InteractiveControlPresenceVisitor: SyntaxVisitor {
    private(set) var foundControl = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if SyntaxInspection.isInteractiveControlConstructor(node) {
            foundControl = true
            return .skipChildren
        }

        return .visitChildren
    }
}
