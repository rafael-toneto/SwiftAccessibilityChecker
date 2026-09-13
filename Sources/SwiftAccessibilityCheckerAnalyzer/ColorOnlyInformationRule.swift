import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct ColorOnlyInformationRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.colorOnlyInformation

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = ColorOnlyInformationVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class ColorOnlyInformationVisitor: SyntaxVisitor {
    private static let statefulColorModifiers: Set<String> = [
        "fill",
        "foregroundColor",
        "foregroundStyle",
        "stroke",
        "tint"
    ]

    private static let supportedVisualRoots: Set<String> = [
        "Capsule",
        "Circle",
        "Ellipse",
        "Image",
        "Rectangle",
        "RoundedRectangle"
    ]

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
            let modifierName = SyntaxInspection.modifierName(of: node),
            Self.statefulColorModifiers.contains(modifierName),
            let colorArgument = node.arguments.first?.expression,
            SyntaxInspection.containsTernary(in: colorArgument),
            let expression = SyntaxInspection.outermostChainedExpression(containing: node),
            let rootCall = SyntaxInspection.rootFunctionCall(in: expression),
            let rootName = SyntaxInspection.calledName(of: rootCall),
            Self.supportedVisualRoots.contains(rootName),
            SyntaxInspection.isSwiftUIConstructor(rootCall, named: rootName),
            !hasNonColorAlternative(in: expression),
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

    private func hasNonColorAlternative(in expression: ExprSyntax) -> Bool {
        if SyntaxInspection.modifierCalls(in: expression).contains(where: {
            guard
                let modifierName = SyntaxInspection.modifierName(of: $0),
                modifierName == "accessibilityLabel"
                    || modifierName == "accessibilityValue",
                SyntaxInspection.isModifierEnabled($0),
                let value = $0.arguments.first?.expression
            else {
                return false
            }

            if SyntaxInspection.containsTernary(in: value) {
                return true
            }

            return SyntaxInspection.literalText(in: value) == nil
        }) {
            return true
        }

        let conditionalImageVisitor = ConditionalImageNameVisitor()
        conditionalImageVisitor.walk(expression)
        if conditionalImageVisitor.foundConditionalImageName {
            return true
        }

        return SyntaxInspection.modifierCalls(in: expression).contains { call in
            guard
                SyntaxInspection.modifierName(of: call) == "overlay",
                overlayProvidesStateAlternative(call)
            else {
                return false
            }

            return true
        }
    }

    private func overlayProvidesStateAlternative(
        _ call: FunctionCallExprSyntax
    ) -> Bool {
        var content: [Syntax] = call.arguments.map { Syntax($0.expression) }
        if let trailingClosure = call.trailingClosure {
            content.append(Syntax(trailingClosure))
        }
        content.append(contentsOf: call.additionalTrailingClosures.map {
            Syntax($0.closure)
        })

        let containsState = content.contains {
            SyntaxInspection.containsTernary(in: $0)
        }
        let containsAlternative = content.contains {
            SyntaxInspection.containsFunctionCall(named: "Text", in: $0)
                || SyntaxInspection.containsFunctionCall(named: "Image", in: $0)
                || SyntaxInspection.containsFunctionCall(named: "Label", in: $0)
        }

        return containsState && containsAlternative
    }
}

private final class ConditionalImageNameVisitor: SyntaxVisitor {
    private(set) var foundConditionalImageName = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard SyntaxInspection.isSwiftUIConstructor(node, named: "Image") else {
            return .visitChildren
        }

        if node.arguments.contains(where: {
            SyntaxInspection.containsTernary(in: $0.expression)
        }) {
            foundConditionalImageName = true
            return .skipChildren
        }

        return .visitChildren
    }
}
