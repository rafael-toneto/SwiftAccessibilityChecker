import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct SmallTouchTargetRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.smallTouchTarget
    public static let recommendedMinimumSize = 44.0

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = SmallTouchTargetVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class SmallTouchTargetVisitor: SyntaxVisitor {
    private let filePath: String
    private let locationConverter: SourceLocationConverter
    private let rule: AccessibilityRuleDefinition
    private var diagnosedExpressionOffsets: Set<Int> = []

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
            SyntaxInspection.modifierName(of: node) == "frame",
            let expression = SyntaxInspection.outermostChainedExpression(containing: node),
            SyntaxInspection.hasRootInteractiveControl(in: expression),
            let member = node.calledExpression.as(MemberAccessExprSyntax.self)
        else {
            return .visitChildren
        }

        let width = constrainedDimension(
            in: node,
            exactLabel: "width",
            maximumLabel: "maxWidth"
        )
        let height = constrainedDimension(
            in: node,
            exactLabel: "height",
            maximumLabel: "maxHeight"
        )

        guard
            width.map({ $0 < SmallTouchTargetRule.recommendedMinimumSize }) == true
                || height.map({ $0 < SmallTouchTargetRule.recommendedMinimumSize }) == true
        else {
            return .visitChildren
        }

        let expressionOffset = expression.positionAfterSkippingLeadingTrivia.utf8Offset
        guard diagnosedExpressionOffsets.insert(expressionOffset).inserted else {
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

    private func constrainedDimension(
        in node: FunctionCallExprSyntax,
        exactLabel: String,
        maximumLabel: String
    ) -> Double? {
        let argument = node.arguments.first {
            $0.label?.text == exactLabel || $0.label?.text == maximumLabel
        }

        guard let argument else {
            return nil
        }

        return SyntaxInspection.literalNumber(in: argument.expression)
    }
}
