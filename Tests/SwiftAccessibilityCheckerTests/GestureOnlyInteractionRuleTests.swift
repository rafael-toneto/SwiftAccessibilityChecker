import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import Testing

@Suite("GestureOnlyInteractionRule")
struct GestureOnlyInteractionRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [GestureOnlyInteractionRule()])

    @Test("Detects a tap gesture used as the only interaction")
    func detectsTapGesture() {
        let source = "Image(systemName: \"trash\").onTapGesture(perform: delete)"

        let diagnostics = analyzer.analyze(source: source, filePath: "Toolbar.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC008")
        #expect(
            diagnostics.first?.message
                == "Gesture-only interaction may need an accessible control role or action"
        )
    }

    @Test("Accepts a single tap with an explicit Button trait")
    func acceptsButtonTrait() {
        let source = """
        Text("Delete")
            .onTapGesture(perform: delete)
            .accessibilityAddTraits(.isButton)
        """

        #expect(analyzer.analyze(source: source, filePath: "Toolbar.swift").isEmpty)
    }

    @Test("Accepts an accessibility action")
    func acceptsAccessibilityAction() {
        let source = """
        Image(systemName: "trash")
            .onTapGesture(perform: delete)
            .accessibilityAction(delete)
        """

        #expect(analyzer.analyze(source: source, filePath: "Toolbar.swift").isEmpty)
    }

    @Test("Ignores a gesture added to a standard control")
    func ignoresStandardControl() {
        let source = "Button(\"Delete\", action: delete).onTapGesture(perform: logTap)"

        #expect(analyzer.analyze(source: source, filePath: "Toolbar.swift").isEmpty)
    }

    @Test("Does not assume a similarly named factory view is a SwiftUI control")
    func detectsGestureOnFactoryView() {
        let source = "Factory.Button().onTapGesture(perform: activate)"

        #expect(
            analyzer.analyze(source: source, filePath: "Factory.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("A Button trait alone does not make a double tap accessible")
    func detectsDoubleTapWithOnlyTrait() {
        let source = """
        Image("photo")
            .onTapGesture(count: 2, perform: zoom)
            .accessibilityAddTraits(.isButton)
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Gallery.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("Accepts a double tap with an accessibility action")
    func acceptsDoubleTapWithAction() {
        let source = """
        Image("photo")
            .onTapGesture(count: 2, perform: zoom)
            .accessibilityAction(zoom)
        """

        #expect(analyzer.analyze(source: source, filePath: "Gallery.swift").isEmpty)
    }

    @Test("A role alone does not expose a long-press action")
    func detectsLongPressWithOnlyTrait() {
        let source = """
        Text("Options")
            .onLongPressGesture(perform: showOptions)
            .accessibilityAddTraits(.isButton)
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Options.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("Detects a long press added to a standard control")
    func detectsLongPressOnButton() {
        let source = """
        Button("Options", action: openOptions)
            .onLongPressGesture(perform: showMenu)
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Options.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("Accepts a long press with an accessibility action")
    func acceptsLongPressWithAction() {
        let source = """
        Text("Options")
            .onLongPressGesture(perform: showOptions)
            .accessibilityAction(showOptions)
        """

        #expect(analyzer.analyze(source: source, filePath: "Options.swift").isEmpty)
    }

    @Test("Does not use a child trait for a container gesture")
    func doesNotUseChildTraitForContainer() {
        let source = """
        VStack {
            Text("Child").accessibilityAddTraits(.isButton)
        }
        .onTapGesture(perform: activateContainer)
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Container.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("Does not use an overlay trait for the receiver gesture")
    func doesNotUseOverlayTraitForReceiver() {
        let source = """
        Rectangle()
            .overlay(Text("Badge").accessibilityAddTraits(.isButton))
            .onTapGesture(perform: select)
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Badge.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("Detects gestures on variable and member roots")
    func detectsGesturesOnNonConstructorRoots() {
        let source = """
        card.onTapGesture(perform: openCard)
        model.thumbnail.onTapGesture(perform: openPhoto)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "Cards.swift")

        #expect(diagnostics.count == 2)
        #expect(diagnostics.allSatisfy { $0.ruleIdentifier == "SAC008" })
    }

    @Test("A Button trait does not make a dynamic tap count accessible")
    func detectsDynamicTapCountWithOnlyTrait() {
        let source = """
        Image("photo")
            .onTapGesture(count: requiredTapCount, perform: zoom)
            .accessibilityAddTraits(.isButton)
        """

        #expect(
            analyzer.analyze(source: source, filePath: "Gallery.swift")
                .map(\.ruleIdentifier) == ["SAC008"]
        )
    }

    @Test("Emits one diagnostic for a gesture-only expression chain")
    func emitsOneDiagnosticPerChain() {
        let source = """
        Image("photo")
            .onTapGesture(perform: select)
            .onLongPressGesture(perform: showMenu)
        """

        #expect(analyzer.analyze(source: source, filePath: "Gallery.swift").count == 1)
    }

    @Test("Reports the gesture modifier location")
    func reportsGestureLocation() {
        let source = """
        Image("photo")
            .onTapGesture(perform: select)
        """

        let diagnostic = analyzer.analyze(source: source, filePath: "Gallery.swift").first

        #expect(diagnostic?.line == 2)
        #expect(diagnostic?.column == 5)
    }
}
