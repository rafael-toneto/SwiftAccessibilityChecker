import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter
import Testing

@Suite("FixedFontSizeRule")
struct FixedFontSizeRuleTests {
    private let analyzer = SwiftSourceAnalyzer(rules: [FixedFontSizeRule()])

    @Test("Detects inferred .system font")
    func detectsInferredSystemFont() {
        let source = """
        Text("Profile")
            .font(.system(size: 16))
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.ruleIdentifier == "SAC003")
        #expect(diagnostics.first?.severity == .medium)
        #expect(diagnostics.first?.message == "Fixed font size may not support Dynamic Type")
    }

    @Test("Detects qualified Font.system font")
    func detectsQualifiedSystemFont() {
        let source = """
        Text("Profile")
            .font(Font.system(size: 16))
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.map(\.ruleIdentifier) == ["SAC003"])
    }

    @Test("Does not detect a Dynamic Type style")
    func doesNotDetectDynamicTypeStyle() {
        let source = """
        Text("Profile")
            .font(.headline)
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "ProfileView.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Does not detect a standalone Font.system call")
    func doesNotDetectStandaloneSystemCall() {
        let source = "let font = Font.system(size: 16)"

        let diagnostics = analyzer.analyze(source: source, filePath: "FontTheme.swift")

        #expect(diagnostics.isEmpty)
    }

    @Test("Reports the line and column of the font modifier")
    func reportsLocationOfFontModifierPeriod() {
        let source = """
        import SwiftUI

        struct ProfileView: View {
            var body: some View {
                Text("Profile")
                    .font(.system(size: 16))
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

    @Test("Detects multiple occurrences")
    func detectsMultipleOccurrences() {
        let source = """
        VStack {
            Text("Profile")
                .font(.system(size: 16))
            Text("Settings")
                .font(Font.system(size: 18))
        }
        """

        let diagnostics = analyzer.analyze(source: source, filePath: "ContentView.swift")

        #expect(diagnostics.count == 2)
        #expect(diagnostics.map(\.line) == [3, 5])
    }

    @Test("Formats an Xcode diagnostic exactly")
    func formatsXcodeDiagnosticExactly() {
        let diagnostic = Diagnostic(
            rule: AccessibilityRuleDefinitions.fixedFontSize,
            filePath: "ProfileView.swift",
            line: 18,
            column: 9
        )

        #expect(
            XcodeDiagnosticFormatter.format(diagnostic)
                == "ProfileView.swift:18:9: warning: "
                + "Fixed font size may not support Dynamic Type [SAC003] [medium]"
        )
    }
}
