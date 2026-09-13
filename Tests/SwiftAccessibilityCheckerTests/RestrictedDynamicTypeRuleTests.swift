import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("RestrictedDynamicTypeRule")
struct RestrictedDynamicTypeRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [RestrictedDynamicTypeRule()])

    @Test("Detects a fixed Dynamic Type size")
    func detectsFixedDynamicTypeSize() {
        let source = """
        Text("Profile")
            .dynamicTypeSize(.large)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC009")
        #expect(diagnostics.first?.severity == .medium)
        #expect(
            diagnostics.first?.message
                == "A fixed or capped Dynamic Type size may limit accessible text scaling"
        )
    }

    @Test("Detects a qualified fixed Dynamic Type size")
    func detectsQualifiedFixedDynamicTypeSize() {
        let source = "Text(\"Profile\").dynamicTypeSize(DynamicTypeSize.accessibility1)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Detects a closed range capped before accessibility sizes")
    func detectsClosedRangeWithoutAccessibilitySizes() {
        let source = "Text(\"Profile\").dynamicTypeSize(.small ... .xxxLarge)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Detects a partial range capped before accessibility sizes")
    func detectsPartialRangeWithoutAccessibilitySizes() {
        let source = "Text(\"Profile\").dynamicTypeSize(...DynamicTypeSize.xxxLarge)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Detects a closed range capped before the largest accessibility size")
    func detectsClosedRangeCappedAtAccessibilityOne() {
        let source = "Text(\"Profile\").dynamicTypeSize(.small ... .accessibility1)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Detects a partial range capped before the largest accessibility size")
    func detectsPartialRangeCappedAtAccessibilityThree() {
        let source = "Text(\"Profile\").dynamicTypeSize(...DynamicTypeSize.accessibility3)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Detects a closed range capped at accessibility4")
    func detectsClosedRangeCappedAtAccessibilityFour() {
        let source = "Text(\"Profile\").dynamicTypeSize(.small ... .accessibility4)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Detects a half-open range that excludes accessibility5")
    func detectsHalfOpenRangeExcludingAccessibilityFive() {
        let source = "Text(\"Profile\").dynamicTypeSize(.small ..< .accessibility5)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC009"])
    }

    @Test("Accepts a closed range that includes accessibility5")
    func acceptsClosedRangeThroughAccessibilityFive() {
        let source = "Text(\"Profile\").dynamicTypeSize(.small ... .accessibility5)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Accepts a partial range that includes accessibility5")
    func acceptsPartialRangeThroughAccessibilityFive() {
        let source = "Text(\"Profile\").dynamicTypeSize(...DynamicTypeSize.accessibility5)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Does not detect a lower-bound-only range")
    func doesNotDetectLowerBoundOnlyRange() {
        let source = "Text(\"Profile\").dynamicTypeSize(.large...)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Does not guess the type of an unknown expression")
    func doesNotDetectUnknownExpression() {
        let source = "Text(\"Profile\").dynamicTypeSize(supportedSizes)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Ignores unrelated modifiers")
    func ignoresUnrelatedModifiers() {
        let source = "Text(\"Profile\").font(.headline)"

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Reports the Dynamic Type modifier location")
    func reportsModifierLocation() {
        let source = """
        import SwiftUI

        struct ProfileView: View {
            var body: some View {
                Text("Profile")
                    .dynamicTypeSize(.xLarge ... .xxxLarge)
            }
        }
        """

        let diagnostic = analyzer.analyze(
            source: source,
            filePath: "ProfileView.swift"
        ).first

        #expect(diagnostic?.line == 6)
        #expect(diagnostic?.column == 13)
    }
}
