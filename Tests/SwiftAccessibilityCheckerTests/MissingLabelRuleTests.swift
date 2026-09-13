import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("MissingLabelRule")
struct MissingLabelRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [MissingLabelRule()])

    @Test("Detects an image-only Button with action argument")
    func detectsImageOnlyButtonWithActionArgument() {
        let source = """
        Button(action: delete) {
            Image(systemName: "trash")
        }
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC001")
        #expect(diagnostics.first?.severity == .high)
        #expect(
            diagnostics.first?.message
                == "Button with image-only or empty content should provide an accessibility label"
        )
    }

    @Test("Detects an image-only Button with multiple trailing closures")
    func detectsImageOnlyButtonWithLabelClosure() {
        let source = """
        Button {
            delete()
        } label: {
            Image(systemName: "trash")
        }
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC001"])
    }

    @Test("Accepts a Button title and system image")
    func acceptsTitleAndSystemImageInitializer() {
        let source = "Button(\"Delete\", systemImage: \"trash\", action: delete)"

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Detects an empty Button title with a system image")
    func detectsEmptyTitleAndSystemImageInitializer() {
        let source = "Button(\"\", systemImage: \"plus\", action: add)"

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC001"])
    }

    @Test("Accepts visible text in the Button label")
    func acceptsVisibleTextInLabel() {
        let source = """
        Button(action: delete) {
            HStack {
                Image(systemName: "trash")
                Text("Delete")
            }
        }
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Accepts a Button-level accessibility label")
    func acceptsButtonAccessibilityLabel() {
        let source = """
        Button(action: delete) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete")
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Does not accept a disabled Button-level accessibility label")
    func detectsDisabledButtonAccessibilityLabel() {
        let source = """
        Button(action: delete) {
            Image(systemName: "trash")
        }
        .accessibilityLabel("Delete", isEnabled: false)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC001"])
    }

    @Test("Accepts an image label inherited by the Button")
    func acceptsImageAccessibilityLabel() {
        let source = """
        Button(action: delete) {
            Image(systemName: "trash")
                .accessibilityLabel("Delete")
        }
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Ignores a similarly named factory method")
    func ignoresFactoryMethod() {
        let source = "Factory.Button(action: delete) { Image(systemName: \"trash\") }"

        let diagnostics = analyzer.analyze(source: source, filePath: "Factory.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Reports the Button location")
    func reportsButtonLocation() {
        let source = """
        struct Toolbar {
            var body: some View {
                Button(action: delete) {
                    Image(systemName: "trash")
                }
            }
        }
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Toolbar.swift").first

        #expect(diagnostic?.line == 3)
        #expect(diagnostic?.column == 9)
    }
}
