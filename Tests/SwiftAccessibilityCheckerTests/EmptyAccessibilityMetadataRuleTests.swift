import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("EmptyAccessibilityMetadataRule")
struct EmptyAccessibilityMetadataRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [EmptyAccessibilityMetadataRule()])

    @Test("Detects an empty accessibility label")
    func detectsEmptyLabel() {
        let source = "Image(\"chart\").accessibilityLabel(\"\")"

        let diagnostics = analyzer.analyze(source: source, filePath: "Chart.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC006")
        #expect(diagnostics.first?.message == "Accessibility label must not be empty")
    }

    @Test("Detects whitespace in a Text accessibility label")
    func detectsWhitespaceTextLabel() {
        let source = "Image(\"chart\").accessibilityLabel(Text(\"   \"))"

        #expect(
            analyzer.analyze(source: source, filePath: "Chart.swift")
                .map(\.ruleIdentifier) == ["SAC006"]
        )
    }

    @Test("Detects an empty LocalizedStringKey accessibility label")
    func detectsEmptyLocalizedStringKeyLabel() {
        let source = "Image(\"chart\").accessibilityLabel(LocalizedStringKey(\"\"))"

        #expect(
            analyzer.analyze(source: source, filePath: "Chart.swift")
                .map(\.ruleIdentifier) == ["SAC006"]
        )
    }

    @Test("Detects escaped whitespace in accessibility metadata")
    func detectsEscapedWhitespace() {
        let source = #"Image("chart").accessibilityLabel("\t\n")"#

        #expect(
            analyzer.analyze(source: source, filePath: "Chart.swift")
                .map(\.ruleIdentifier) == ["SAC006"]
        )
    }

    @Test("Detects empty values and hints")
    func detectsEmptyValuesAndHints() {
        let source = """
        Slider(value: $progress)
            .accessibilityValue("")
            .accessibilityHint(Text(verbatim: "   "))
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Player.swift")

        #expect(diagnostics.count == 2)
        #expect(diagnostics.map(\.message).contains("Accessibility value must not be empty"))
        #expect(diagnostics.map(\.message).contains("Accessibility hint must not be empty"))
    }

    @Test("Accepts nonempty accessibility metadata")
    func acceptsNonemptyMetadata() {
        let source = """
        Image("chart")
            .accessibilityLabel("Quarterly sales")
            .accessibilityHint("Opens details")
        """

        #expect(analyzer.analyze(source: source, filePath: "Chart.swift").isEmpty)
    }

    @Test("Does not guess interpolated metadata")
    func ignoresInterpolatedMetadata() {
        let source = "Image(\"avatar\").accessibilityLabel(\"User \\(name)\")"

        #expect(analyzer.analyze(source: source, filePath: "Avatar.swift").isEmpty)
    }

    @Test("Ignores a disabled empty metadata modifier")
    func ignoresDisabledModifier() {
        let source = "Image(\"chart\").accessibilityLabel(\"\", isEnabled: false)"

        #expect(analyzer.analyze(source: source, filePath: "Chart.swift").isEmpty)
    }

    @Test("Reports the metadata modifier location")
    func reportsMetadataLocation() {
        let source = """
        Image("chart")
            .accessibilityLabel("")
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Chart.swift").first

        #expect(diagnostic?.line == 2)
        #expect(diagnostic?.column == 5)
    }
}
