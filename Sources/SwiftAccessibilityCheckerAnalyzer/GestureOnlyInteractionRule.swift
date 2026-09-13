import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct GestureOnlyInteractionRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.gestureOnlyInteraction

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = GestureOnlyInteractionVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class GestureOnlyInteractionVisitor: SyntaxVisitor {
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
            let gestureName = SyntaxInspection.modifierName(of: node),
            gestureName == "onTapGesture" || gestureName == "onLongPressGesture",
            let expression = SyntaxInspection.outermostChainedExpression(containing: node),
            !isStandardControlSingleTap(
                gesture: node,
                gestureName: gestureName,
                expression: expression
            ),
            !hasAccessibleEquivalent(for: node, gestureName: gestureName, in: expression),
            let member = node.calledExpression.as(MemberAccessExprSyntax.self)
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

    private func hasAccessibleEquivalent(
        for gesture: FunctionCallExprSyntax,
        gestureName: String,
        in expression: ExprSyntax
    ) -> Bool {
        let modifierNames = Set<String>(
            SyntaxInspection.modifierCalls(in: expression).compactMap { call in
                guard SyntaxInspection.isModifierEnabled(call) else {
                    return nil
                }
                return SyntaxInspection.modifierName(of: call)
            }
        )

        if modifierNames.contains("accessibilityRepresentation")
            || modifierNames.contains("accessibilityAction")
            || modifierNames.contains("accessibilityAdjustableAction")
            || modifierNames.contains("accessibilityZoomAction")
        {
            return true
        }

        guard gestureName == "onTapGesture", tapCount(of: gesture) == 1 else {
            return false
        }

        for call in SyntaxInspection.modifierCalls(in: expression)
        where SyntaxInspection.modifierName(of: call) == "accessibilityAddTraits"
            && SyntaxInspection.isModifierEnabled(call) {
            let traitVisitor = InteractiveTraitMemberVisitor()
            call.arguments.forEach { traitVisitor.walk($0.expression) }
            if traitVisitor.foundInteractiveTrait {
                return true
            }
        }

        return false
    }

    private func isStandardControlSingleTap(
        gesture: FunctionCallExprSyntax,
        gestureName: String,
        expression: ExprSyntax
    ) -> Bool {
        guard
            gestureName == "onTapGesture",
            tapCount(of: gesture) == 1,
            SyntaxInspection.hasRootInteractiveControl(in: expression)
        else {
            return false
        }

        return true
    }

    private func tapCount(of node: FunctionCallExprSyntax) -> Int? {
        guard let countArgument = node.arguments.first(where: {
            $0.label?.text == "count"
        }) else {
            return 1
        }

        guard let count = SyntaxInspection.literalNumber(in: countArgument.expression) else {
            return nil
        }

        return Int(exactly: count)
    }
}

private final class InteractiveTraitMemberVisitor: SyntaxVisitor {
    private(set) var foundInteractiveTrait = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.declName.baseName.text
        if name == "isButton" || name == "isLink" {
            foundInteractiveTrait = true
            return .skipChildren
        }

        return .visitChildren
    }
}
