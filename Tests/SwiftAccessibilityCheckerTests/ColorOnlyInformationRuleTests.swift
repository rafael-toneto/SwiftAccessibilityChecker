import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("ColorOnlyInformationRule")
struct ColorOnlyInformationRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [ColorOnlyInformationRule()])

    @Test("Detects a state-dependent shape color")
    func detectsConditionalShapeColor() {
        let source = "Circle().fill(isOnline ? Color.green : Color.red)"

        let diagnostics = analyzer.analyze(source: source, filePath: "Status.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC005")
        #expect(
            diagnostics.first?.message
                == "State-dependent color may need a text, shape, or icon alternative"
        )
    }

    @Test("Detects a state-dependent Image color")
    func detectsConditionalImageColor() {
        let source = "Image(systemName: \"circle.fill\").foregroundStyle(isOnline ? .green : .red)"

        #expect(
            analyzer.analyze(source: source, filePath: "Status.swift")
                .map(\.ruleIdentifier) == ["SAC005"]
        )
    }

    @Test("Ignores a constant decorative color")
    func ignoresConstantColor() {
        let source = "Circle().fill(Color.blue)"

        #expect(analyzer.analyze(source: source, filePath: "Badge.swift").isEmpty)
    }

    @Test("Ignores a similarly named factory shape")
    func ignoresFactoryShape() {
        let source = "Factory.Circle().fill(isOnline ? Color.green : Color.red)"

        #expect(analyzer.analyze(source: source, filePath: "Factory.swift").isEmpty)
    }

    @Test("Ignores text whose meaning is already visible")
    func ignoresConditionalTextColor() {
        let source = "Text(isOnline ? \"Online\" : \"Offline\").foregroundStyle(isOnline ? .green : .red)"

        #expect(analyzer.analyze(source: source, filePath: "Status.swift").isEmpty)
    }

    @Test("Accepts an accessibility description as the paper proposes")
    func acceptsAccessibilityDescription() {
        let source = """
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .accessibilityLabel(isOnline ? "Online" : "Offline")
        """

        #expect(analyzer.analyze(source: source, filePath: "Status.swift").isEmpty)
    }

    @Test("Does not accept constant accessibility metadata as a state alternative")
    func detectsConstantAccessibilityMetadata() {
        let source = """
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .accessibilityLabel("Status")
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Status.swift")
                .map(\.ruleIdentifier) == ["SAC005"]
        )
    }

    @Test("Accepts conditional accessibility metadata as a state alternative")
    func acceptsConditionalAccessibilityMetadata() {
        let source = """
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .accessibilityValue(isOnline ? "Online" : "Offline")
        """

        #expect(analyzer.analyze(source: source, filePath: "Status.swift").isEmpty)
    }

    @Test("Accepts an overlaid icon alternative")
    func acceptsOverlayIcon() {
        let source = """
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .overlay {
                Image(systemName: isOnline ? "checkmark" : "xmark")
            }
        """

        #expect(analyzer.analyze(source: source, filePath: "Status.swift").isEmpty)
    }

    @Test("Does not accept a constant overlay as a state alternative")
    func detectsConstantOverlay() {
        let source = """
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .overlay {
                Image(systemName: "circle")
            }
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Status.swift")
                .map(\.ruleIdentifier) == ["SAC005"]
        )
    }

    @Test("Accepts a changing symbol as a non-color alternative")
    func acceptsConditionalImageName() {
        let source = """
        Image(systemName: isOnline ? "checkmark.circle" : "xmark.circle")
            .foregroundStyle(isOnline ? Color.green : Color.red)
        """

        #expect(analyzer.analyze(source: source, filePath: "Status.swift").isEmpty)
    }

    @Test("Emits one diagnostic per expression chain")
    func emitsOneDiagnosticPerChain() {
        let source = """
        Circle()
            .fill(isOnline ? Color.green : Color.red)
            .stroke(isOnline ? Color.mint : Color.orange)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Status.swift")

        #expect(diagnostics.count == 1)
    }

    @Test("Reports the stateful color modifier location")
    func reportsColorModifierLocation() {
        let source = """
        Circle()
            .fill(isOnline ? .green : .red)
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Status.swift").first

        #expect(diagnostic?.line == 2)
        #expect(diagnostic?.column == 5)
    }
}
