import Foundation
import SwiftSyntax

enum SyntaxInspection {
    static let interactiveControlNames: Set<String> = [
        "Button",
        "ColorPicker",
        "DatePicker",
        "DisclosureGroup",
        "Link",
        "Menu",
        "MultiDatePicker",
        "NavigationLink",
        "Picker",
        "SecureField",
        "ShareLink",
        "Slider",
        "Stepper",
        "TextField",
        "TextEditor",
        "Toggle"
    ]

    static func calledName(of node: FunctionCallExprSyntax) -> String? {
        if let reference = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text
        }

        if let member = node.calledExpression.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text
        }

        return nil
    }

    static func modifierName(of node: FunctionCallExprSyntax) -> String? {
        guard
            let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.base != nil
        else {
            return nil
        }

        return member.declName.baseName.text
    }

    static func isSwiftUIConstructor(
        _ node: FunctionCallExprSyntax,
        named expectedName: String
    ) -> Bool {
        if let reference = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == expectedName
        }

        guard
            let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == expectedName,
            let module = member.base?.as(DeclReferenceExprSyntax.self)
        else {
            return false
        }

        return module.baseName.text == "SwiftUI"
    }

    static func isInteractiveControlConstructor(
        _ node: FunctionCallExprSyntax
    ) -> Bool {
        guard
            let name = calledName(of: node),
            interactiveControlNames.contains(name)
        else {
            return false
        }

        if node.calledExpression.is(DeclReferenceExprSyntax.self) {
            return true
        }

        guard
            let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            let module = member.base?.as(DeclReferenceExprSyntax.self)
        else {
            return false
        }

        return module.baseName.text == "SwiftUI"
    }

    static func outermostChainedExpression(
        containing node: some SyntaxProtocol
    ) -> ExprSyntax? {
        var current = Syntax(node)

        while let parent = current.parent {
            if parent.is(MemberAccessExprSyntax.self)
                || parent.is(FunctionCallExprSyntax.self)
            {
                current = parent
            } else {
                break
            }
        }

        return current.as(ExprSyntax.self)
    }

    static func modifierCalls(in expression: ExprSyntax) -> [FunctionCallExprSyntax] {
        var calls: [FunctionCallExprSyntax] = []
        collectModifierCalls(in: expression, into: &calls)
        return calls
    }

    static func containsModifier(
        named name: String,
        in expression: ExprSyntax
    ) -> Bool {
        modifierCalls(in: expression).contains {
            modifierName(of: $0) == name
        }
    }

    static func containsActiveModifier(
        named name: String,
        in expression: ExprSyntax
    ) -> Bool {
        modifierCalls(in: expression).contains {
            modifierName(of: $0) == name && isModifierEnabled($0)
        }
    }

    static func isModifierEnabled(_ node: FunctionCallExprSyntax) -> Bool {
        guard
            let argument = node.arguments.first(where: {
                $0.label?.text == "isEnabled"
            })
        else {
            return true
        }

        return booleanLiteral(in: argument.expression) != false
    }

    static func rootCallName(in expression: ExprSyntax) -> String? {
        rootFunctionCall(in: expression).flatMap(calledName(of:))
    }

    static func rootFunctionCall(
        in expression: ExprSyntax
    ) -> FunctionCallExprSyntax? {
        if let call = expression.as(FunctionCallExprSyntax.self) {
            if
                let member = call.calledExpression.as(MemberAccessExprSyntax.self),
                let base = member.base,
                let rootCall = rootFunctionCall(in: base)
            {
                return rootCall
            }

            return call
        }

        if
            let member = expression.as(MemberAccessExprSyntax.self),
            let base = member.base
        {
            return rootFunctionCall(in: base)
        }

        return nil
    }

    static func hasRootInteractiveControl(in expression: ExprSyntax) -> Bool {
        guard let rootCall = rootFunctionCall(in: expression) else {
            return false
        }

        return isInteractiveControlConstructor(rootCall)
    }

    static func hasAncestorConstructor(
        named name: String,
        from node: some SyntaxProtocol
    ) -> Bool {
        var ancestor = Syntax(node).parent

        while let current = ancestor {
            if
                let call = current.as(FunctionCallExprSyntax.self),
                isSwiftUIConstructor(call, named: name)
            {
                return true
            }
            ancestor = current.parent
        }

        return false
    }

    static func literalString(in expression: ExprSyntax) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self) else {
            return nil
        }

        var value = ""
        for segment in literal.segments {
            switch segment {
            case .stringSegment(let stringSegment):
                value += stringSegment.content.text
            case .expressionSegment:
                return nil
            }
        }

        if literal.openingPounds == nil {
            value = value
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\r", with: "\r")
                .replacingOccurrences(of: "\\0", with: "\0")
        }

        return value
    }

    static func literalText(in expression: ExprSyntax) -> String? {
        if let value = literalString(in: expression) {
            return value
        }

        guard
            let call = expression.as(FunctionCallExprSyntax.self),
            let calledName = calledName(of: call),
            ["LocalizedStringKey", "LocalizedStringResource", "Text"].contains(calledName),
            let argument = call.arguments.first
        else {
            return nil
        }

        return literalText(in: argument.expression)
    }

    static func literalNumber(in expression: ExprSyntax) -> Double? {
        let literal: String
        if let integer = expression.as(IntegerLiteralExprSyntax.self) {
            literal = integer.literal.text
        } else if let float = expression.as(FloatLiteralExprSyntax.self) {
            literal = float.literal.text
        } else {
            return nil
        }

        return Double(literal.filter { $0 != "_" })
    }

    static func booleanLiteral(in expression: ExprSyntax) -> Bool? {
        if
            let tuple = expression.as(TupleExprSyntax.self),
            tuple.elements.count == 1,
            let element = tuple.elements.first,
            element.label == nil
        {
            return booleanLiteral(in: element.expression)
        }

        guard let literal = expression.as(BooleanLiteralExprSyntax.self) else {
            return nil
        }

        switch literal.literal.text {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }

    static func containsTernary(in node: some SyntaxProtocol) -> Bool {
        let visitor = TernaryPresenceVisitor()
        visitor.walk(node)
        return visitor.foundTernary
    }

    static func containsFunctionCall(
        named name: String,
        in node: some SyntaxProtocol
    ) -> Bool {
        let visitor = FunctionCallPresenceVisitor(expectedName: name)
        visitor.walk(node)
        return visitor.foundCall
    }

    private static func collectModifierCalls(
        in expression: ExprSyntax,
        into calls: inout [FunctionCallExprSyntax]
    ) {
        guard let call = expression.as(FunctionCallExprSyntax.self) else {
            if
                let member = expression.as(MemberAccessExprSyntax.self),
                let base = member.base
            {
                collectModifierCalls(in: base, into: &calls)
            }
            return
        }

        if
            let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            let base = member.base
        {
            collectModifierCalls(in: base, into: &calls)
        }

        calls.append(call)
    }
}

private final class TernaryPresenceVisitor: SyntaxVisitor {
    private(set) var foundTernary = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        foundTernary = true
        return .skipChildren
    }

    override func visit(_ node: UnresolvedTernaryExprSyntax) -> SyntaxVisitorContinueKind {
        foundTernary = true
        return .skipChildren
    }
}

private final class FunctionCallPresenceVisitor: SyntaxVisitor {
    private let expectedName: String
    private(set) var foundCall = false

    init(expectedName: String) {
        self.expectedName = expectedName
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if SyntaxInspection.calledName(of: node) == expectedName {
            foundCall = true
            return .skipChildren
        }

        return .visitChildren
    }
}
