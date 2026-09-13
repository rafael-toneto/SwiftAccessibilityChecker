import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("SmallTouchTargetRule")
struct SmallTouchTargetRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [SmallTouchTargetRule()])

    @Test("Detects an explicitly small Button frame")
    func detectsSmallButtonFrame() {
        let source = """
        Button("Close", action: close)
            .frame(width: 32, height: 32)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Sheet.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC004")
        #expect(
            diagnostics.first?.message
                == "Explicit frame may create a touch target smaller than 44 x 44 points"
        )
    }

    @Test("Detects when either known dimension is below 44 points")
    func detectsOneSmallKnownDimension() {
        let source = "Link(\"Help\", destination: helpURL).frame(width: 60, height: 30)"

        #expect(
            analyzer.analyze(source: source, filePath: "Help.swift")
                .map(\.ruleIdentifier) == ["SAC004"]
        )
    }

    @Test("Accepts a 44 by 44 point target")
    func acceptsRecommendedSize() {
        let source = "Button(\"Close\", action: close).frame(width: 44, height: 44)"

        #expect(analyzer.analyze(source: source, filePath: "Sheet.swift").isEmpty)
    }

    @Test("Detects an explicitly small single dimension")
    func detectsSingleSmallDimensionFrame() {
        let source = "Button(\"Close\", action: close).frame(width: 32)"

        #expect(
            analyzer.analyze(source: source, filePath: "Sheet.swift")
                .map(\.ruleIdentifier) == ["SAC004"]
        )
    }

    @Test("Emits one diagnostic for multiple small frames in one expression chain")
    func emitsOneDiagnosticPerExpressionChain() {
        let source = """
        Button("Close", action: close)
            .frame(width: 32, height: 32)
            .frame(width: 24, height: 24)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Sheet.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC004"])
    }

    @Test("Detects paired maximum dimensions")
    func detectsSmallMaximumDimensions() {
        let source = "Toggle(\"Favorite\", isOn: $favorite).frame(maxWidth: 28, maxHeight: 28)"

        #expect(
            analyzer.analyze(source: source, filePath: "Favorite.swift")
                .map(\.ruleIdentifier) == ["SAC004"]
        )
    }

    @Test("Ignores noninteractive views")
    func ignoresNoninteractiveView() {
        let source = "Image(\"avatar\").frame(width: 24, height: 24)"

        #expect(analyzer.analyze(source: source, filePath: "Avatar.swift").isEmpty)
    }

    @Test("Ignores a similarly named factory control")
    func ignoresFactoryControl() {
        let source = "Factory.Button().frame(width: 24, height: 24)"

        #expect(analyzer.analyze(source: source, filePath: "Factory.swift").isEmpty)
    }

    @Test("Does not guess dimensions from expressions")
    func ignoresDynamicDimensions() {
        let source = "Button(\"Close\", action: close).frame(width: size, height: size)"

        #expect(analyzer.analyze(source: source, filePath: "Sheet.swift").isEmpty)
    }

    @Test("Reports the frame modifier location")
    func reportsFrameLocation() {
        let source = """
        Button("Close", action: close)
            .frame(width: 32, height: 32)
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Sheet.swift").first

        #expect(diagnostic?.line == 2)
        #expect(diagnostic?.column == 5)
    }
}
