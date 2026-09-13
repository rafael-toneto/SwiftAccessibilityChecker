import Foundation
import SwiftAccessibilityCheckerAnalyzer
import Testing

@Suite("Accessibility fixtures")
struct FixtureCoverageTests {
    private let analyzer = SwiftSourceAnalyzer()

    @Test("Accessible fixture has no diagnostics")
    func accessibleFixtureHasNoDiagnostics() throws {
        let source = try fixtureSource(named: "AccessibleExample.swift")

        let diagnostics = analyzer.analyze(
            source: source,
            filePath: "AccessibleExample.swift"
        )

        #expect(diagnostics.isEmpty)
    }

    @Test("Inaccessible fixture covers every default rule")
    func inaccessibleFixtureCoversEveryRule() throws {
        let source = try fixtureSource(named: "InaccessibleExample.swift")

        let diagnostics = analyzer.analyze(
            source: source,
            filePath: "InaccessibleExample.swift"
        )

        #expect(
            diagnostics.map(\.ruleIdentifier) == [
                "SAC001",
                "SAC002",
                "SAC003",
                "SAC004",
                "SAC005",
                "SAC006",
                "SAC007",
                "SAC008",
                "SAC009"
            ]
        )
        #expect(diagnostics.allSatisfy { $0.sourceExcerpt?.isEmpty == false })
    }

    private func fixtureSource(named name: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fixture = repositoryRoot
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(name)

        return try String(contentsOf: fixture, encoding: .utf8)
    }
}
