import SwiftAccessibilityCheckerCore
import SwiftSyntax

public struct RestrictedDynamicTypeRule: AccessibilityRule {
    public let definition = AccessibilityRuleDefinitions.restrictedDynamicType

    public init() {}

    public func analyze(
        syntax: SourceFileSyntax,
        filePath: String,
        locationConverter: SourceLocationConverter
    ) -> [Diagnostic] {
        let visitor = RestrictedDynamicTypeVisitor(
            filePath: filePath,
            locationConverter: locationConverter,
            rule: definition
        )
        visitor.walk(syntax)
        return visitor.diagnostics
    }
}

private final class RestrictedDynamicTypeVisitor: SyntaxVisitor {
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
            let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "dynamicTypeSize",
            node.arguments.count == 1,
            let argument = node.arguments.first,
            argument.label == nil,
            restrictsAccessibilitySizes(argument.expression)
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

    private func restrictsAccessibilitySizes(_ expression: ExprSyntax) -> Bool {
        let expression = unwrapped(expression)

        if dynamicTypeCategory(in: expression) != nil {
            return true
        }

        if let prefixRange = expression.as(PrefixOperatorExprSyntax.self) {
            return hasInaccessibleUpperBound(
                prefixRange.expression,
                rangeOperator: prefixRange.operator.text
            )
        }

        guard let range = expression.as(SequenceExprSyntax.self) else {
            return false
        }

        let elements = Array(range.elements)
        guard
            elements.count == 3,
            let rangeOperator = elements[1].as(BinaryOperatorExprSyntax.self)
        else {
            return false
        }

        return hasInaccessibleUpperBound(
            elements[2],
            rangeOperator: rangeOperator.operator.text
        )
    }

    private func hasInaccessibleUpperBound(
        _ expression: ExprSyntax,
        rangeOperator: String
    ) -> Bool {
        guard let category = dynamicTypeCategory(in: unwrapped(expression)) else {
            return false
        }

        switch rangeOperator {
        case "...":
            return category < .accessibility5
        case "..<":
            return category <= .accessibility5
        default:
            return false
        }
    }

    private func dynamicTypeCategory(in expression: ExprSyntax) -> DynamicTypeCategory? {
        guard
            let member = expression.as(MemberAccessExprSyntax.self),
            isSupportedDynamicTypeBase(member.base)
        else {
            return nil
        }

        return DynamicTypeCategory(rawValue: member.declName.baseName.text)
    }

    private func isSupportedDynamicTypeBase(_ base: ExprSyntax?) -> Bool {
        guard let base else {
            return true
        }

        if let reference = base.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == "DynamicTypeSize"
        }

        guard let member = base.as(MemberAccessExprSyntax.self) else {
            return false
        }

        return member.declName.baseName.text == "DynamicTypeSize"
            && member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "SwiftUI"
    }

    private func unwrapped(_ expression: ExprSyntax) -> ExprSyntax {
        guard
            let tuple = expression.as(TupleExprSyntax.self),
            tuple.elements.count == 1,
            let element = tuple.elements.first,
            element.label == nil
        else {
            return expression
        }

        return unwrapped(element.expression)
    }
}

private enum DynamicTypeCategory: String, Comparable {
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    case accessibility1
    case accessibility2
    case accessibility3
    case accessibility4
    case accessibility5

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .xSmall: 0
        case .small: 1
        case .medium: 2
        case .large: 3
        case .xLarge: 4
        case .xxLarge: 5
        case .xxxLarge: 6
        case .accessibility1: 7
        case .accessibility2: 8
        case .accessibility3: 9
        case .accessibility4: 10
        case .accessibility5: 11
        }
    }
}
