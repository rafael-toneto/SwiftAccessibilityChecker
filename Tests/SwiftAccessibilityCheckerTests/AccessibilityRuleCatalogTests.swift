import SwiftAccessibilityCheckerAnalyzer
import Testing

@Suite("Accessibility rule catalog")
struct AccessibilityRuleCatalogTests {
    @Test("Registers every rule exactly once in identifier order")
    func registersEveryRuleOnce() {
        let identifiers = AccessibilityRuleCatalog.defaultRules.map(\.identifier)

        #expect(
            identifiers == [
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
        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test("Every rule provides actionable academic metadata")
    func everyRuleProvidesMetadata() {
        for rule in AccessibilityRuleCatalog.defaultRules {
            let definition = rule.definition

            #expect(!definition.title.isEmpty)
            #expect(!definition.description.isEmpty)
            #expect(!definition.rationale.isEmpty)
            #expect(!definition.suggestion.isEmpty)
            #expect(!definition.references.isEmpty)
            #expect(definition.references.allSatisfy { !$0.url.isEmpty })
        }
    }
}
