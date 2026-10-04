import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct FixedFontSizeRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.fixedFontSize

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = FixedFontSizeVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class FixedFontSizeVisitor: SyntaxVisitor {
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
            let fontMember = node.calledExpression.as(MemberAccessExprSyntax.self),
            fontMember.declName.baseName.text == "font",
            node.arguments.count == 1,
            let fontArgument = node.arguments.first,
            fontArgument.label == nil,
            let systemCall = fontArgument.expression.as(FunctionCallExprSyntax.self),
            let systemMember = systemCall.calledExpression.as(MemberAccessExprSyntax.self),
            systemMember.declName.baseName.text == "system",
            isSupportedSystemBase(systemMember.base),
            systemCall.arguments.contains(where: { $0.label?.text == "size" }),
            !isImageChain(fontMember.base)
        else {
            return .visitChildren
        }

        let location = locationConverter.location(
            for: fontMember.period.positionAfterSkippingLeadingTrivia
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

    private func isSupportedSystemBase(_ base: ExprSyntax?) -> Bool {
        guard let base else {
            return true
        }

        guard let reference = base.as(DeclReferenceExprSyntax.self) else {
            return false
        }

        return reference.baseName.text == "Font"
    }

    // A font applied to a symbol changes its visual size; it is not a fixed text
    // size. Follow only the receiver chain, never nested children of a container.
    private func isImageChain(_ expression: ExprSyntax?) -> Bool {
        guard let call = expression?.as(FunctionCallExprSyntax.self) else {
            return false
        }

        if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == "Image"
        }

        if let modifier = call.calledExpression.as(MemberAccessExprSyntax.self) {
            return isImageChain(modifier.base)
        }

        return false
    }
}
