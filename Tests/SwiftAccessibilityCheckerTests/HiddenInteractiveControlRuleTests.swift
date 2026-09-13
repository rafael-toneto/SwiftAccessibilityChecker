import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("HiddenInteractiveControlRule")
struct HiddenInteractiveControlRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [HiddenInteractiveControlRule()])

    @Test("Detects a Button hidden from accessibility")
    func detectsHiddenButton() {
        let source = "Button(\"Delete\", action: delete).accessibilityHidden(true)"

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC007")
        #expect(
            diagnostics.first?.message
                == "Interactive control is hidden from accessibility features"
        )
    }

    @Test("Detects multiple standard interactive controls")
    func detectsStandardInteractiveControls() {
        let source = """
        Toggle("Favorite", isOn: $favorite).accessibilityHidden(true)
        TextField("Name", text: $name).accessibilityHidden(true)
        Link("Help", destination: helpURL).accessibilityHidden(true)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Form.swift")

        #expect(diagnostics.count == 3)
        #expect(diagnostics.allSatisfy { $0.ruleIdentifier == "SAC007" })
    }

    @Test("Accepts accessibilityHidden false")
    func acceptsHiddenFalse() {
        let source = "Button(\"Delete\", action: delete).accessibilityHidden(false)"

        #expect(analyzer.analyze(source: source, filePath: "Toolbar.swift").isEmpty)
    }

    @Test("Ignores a disabled accessibilityHidden modifier")
    func ignoresDisabledModifier() {
        let source = """
        Button("Delete", action: delete)
            .accessibilityHidden(true, isEnabled: false)
        """

        #expect(analyzer.analyze(source: source, filePath: "Toolbar.swift").isEmpty)
    }

    @Test("Allows decorative images to be hidden")
    func allowsDecorativeImageToBeHidden() {
        let source = "Image(\"texture\").accessibilityHidden(true)"

        #expect(analyzer.analyze(source: source, filePath: "Card.swift").isEmpty)
    }

    @Test("Detects an interactive control hidden by a container")
    func detectsControlInsideHiddenContainer() {
        let source = """
        VStack {
            Button("Delete", action: delete)
        }
        .accessibilityHidden(true)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC007"])
    }

    @Test("Detects newer standard controls hidden from accessibility")
    func detectsColorPickerAndTextEditor() {
        let source = """
        ColorPicker("Accent", selection: $accent)
            .accessibilityHidden(true)
        TextEditor(text: $notes)
            .accessibilityHidden(true)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Editor.swift")

        #expect(diagnostics.count == 2)
        #expect(diagnostics.allSatisfy { $0.ruleIdentifier == "SAC007" })
    }

    @Test("Reports the accessibilityHidden modifier location")
    func reportsHiddenModifierLocation() {
        let source = """
        Button("Delete", action: delete)
            .accessibilityHidden(true)
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Toolbar.swift").first

        #expect(diagnostic?.line == 2)
        #expect(diagnostic?.column == 5)
    }
}
