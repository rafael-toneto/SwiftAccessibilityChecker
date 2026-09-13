import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("ImageAccessibilityRule")
struct ImageAccessibilityRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [ImageAccessibilityRule()])

    @Test("Detects an untreated standalone Image")
    func detectsUntreatedImage() {
        let diagnostics = analyzer.analyze(
            source: "Image(\"chart\")",
            filePath: "Dashboard.swift"
        )

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC002")
        #expect(
            diagnostics.first?.message
                == "Image should be labeled or explicitly hidden from accessibility"
        )
    }

    @Test("Accepts a labeled Image")
    func acceptsLabeledImage() {
        let source = "Image(\"chart\").accessibilityLabel(\"Sales increased\")"

        #expect(analyzer.analyze(source: source, filePath: "Dashboard.swift").isEmpty)
    }

    @Test("Does not accept a disabled Image accessibility label")
    func detectsImageWithDisabledAccessibilityLabel() {
        let source = "Image(\"chart\").accessibilityLabel(\"Sales increased\", isEnabled: false)"

        #expect(
            analyzer.analyze(source: source, filePath: "Dashboard.swift")
                .map(\.ruleIdentifier) == ["SAC002"]
        )
    }

    @Test("Accepts an accessibility representation")
    func acceptsAccessibilityRepresentation() {
        let source = """
        Image("status")
            .accessibilityRepresentation {
                Label("Online", systemImage: "checkmark")
            }
        """

        #expect(analyzer.analyze(source: source, filePath: "Status.swift").isEmpty)
    }

    @Test("Accepts an Image hidden from accessibility")
    func acceptsHiddenImage() {
        let source = "Image(\"texture\").accessibilityHidden(true)"

        #expect(analyzer.analyze(source: source, filePath: "Card.swift").isEmpty)
    }

    @Test("Does not treat accessibilityHidden false as decorative")
    func detectsImageWhenHiddenIsFalse() {
        let source = "Image(\"chart\").accessibilityHidden(false)"

        #expect(
            analyzer.analyze(source: source, filePath: "Dashboard.swift")
                .map(\.ruleIdentifier) == ["SAC002"]
        )
    }

    @Test("Accepts the decorative Image initializer")
    func acceptsDecorativeInitializer() {
        let source = "Image(decorative: \"texture\")"

        #expect(analyzer.analyze(source: source, filePath: "Card.swift").isEmpty)
    }

    @Test("Leaves image-only Button handling to SAC001")
    func ignoresImageInsideButton() {
        let source = """
        Button(action: delete) {
            Image(systemName: "trash")
        }
        """

        #expect(analyzer.analyze(source: source, filePath: "Toolbar.swift").isEmpty)
    }

    @Test("Accepts an Image used as a Label icon")
    func ignoresImageInsideLabel() {
        let source = """
        Label {
            Text("Warning")
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        """

        #expect(analyzer.analyze(source: source, filePath: "Alert.swift").isEmpty)
    }

    @Test("Reports the Image location")
    func reportsImageLocation() {
        let source = """
        VStack {
            Image("chart")
        }
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Dashboard.swift").first

        #expect(diagnostic?.line == 2)
        #expect(diagnostic?.column == 5)
    }
}
