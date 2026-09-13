import Foundation
import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct MissingLabelRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.missingLabel

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = MissingLabelVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class MissingLabelVisitor: SyntaxVisitor {
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
            SyntaxInspection.isSwiftUIConstructor(node, named: "Button"),
            let expression = SyntaxInspection.outermostChainedExpression(containing: node),
            !SyntaxInspection.containsActiveModifier(
                named: "accessibilityLabel",
                in: expression
            )
        else {
            return .visitChildren
        }

        if hasNonemptyTitleArgument(node) {
            return .visitChildren
        }

        let hasEmptyTitle = hasEmptyTitleArgument(node)
        let labelSummary = summarizeLabel(of: node)
        let hasUnlabeledImageOnlyContent = labelSummary?.containsImage == true
            && labelSummary?.containsText == false
            && labelSummary?.containsAccessibilityLabel == false

        guard hasEmptyTitle || hasUnlabeledImageOnlyContent else {
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

    private func hasNonemptyTitleArgument(_ node: FunctionCallExprSyntax) -> Bool {
        guard
            let firstArgument = node.arguments.first,
            firstArgument.label == nil,
            let title = SyntaxInspection.literalText(in: firstArgument.expression)
        else {
            return false
        }

        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func hasEmptyTitleArgument(_ node: FunctionCallExprSyntax) -> Bool {
        guard
            node.arguments.contains(where: { $0.label?.text == "systemImage" }),
            let firstArgument = node.arguments.first,
            firstArgument.label == nil,
            let title = SyntaxInspection.literalText(in: firstArgument.expression)
        else {
            return false
        }

        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func summarizeLabel(of node: FunctionCallExprSyntax) -> ButtonLabelSummary? {
        var closures: [ClosureExprSyntax] = []

        for argument in node.arguments where argument.label?.text == "label" {
            if let closure = argument.expression.as(ClosureExprSyntax.self) {
                closures.append(closure)
            }
        }

        for trailingClosure in node.additionalTrailingClosures
        where trailingClosure.label.text == "label" {
            closures.append(trailingClosure.closure)
        }

        if
            closures.isEmpty,
            let trailingClosure = node.trailingClosure,
            node.arguments.contains(where: {
                $0.label?.text == "action" || $0.label?.text == "intent"
            })
        {
            closures.append(trailingClosure)
        }

        guard !closures.isEmpty else {
            return nil
        }

        let summary = ButtonLabelSummary()
        closures.forEach { summary.walk($0) }
        return summary
    }
}

private final class ButtonLabelSummary: SyntaxVisitor {
    private(set) var containsImage = false
    private(set) var containsText = false
    private(set) var containsAccessibilityLabel = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        switch SyntaxInspection.calledName(of: node) {
        case "Image":
            containsImage = true
        case "Label", "Text":
            containsText = true
        case "accessibilityLabel":
            containsAccessibilityLabel = SyntaxInspection.isModifierEnabled(node)
        default:
            break
        }

        return .visitChildren
    }
}
