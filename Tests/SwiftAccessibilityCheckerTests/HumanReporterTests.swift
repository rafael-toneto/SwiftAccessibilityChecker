import Foundation
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter
import Testing

@Suite("Human-readable reports")
struct HumanReporterTests {
    @Test("All current rules explain an actionable review and verification")
    func completeGuidanceForAllRules() {
        let rules = [
            AccessibilityRuleDefinitions.missingLabel,
            AccessibilityRuleDefinitions.imageAccessibility,
            AccessibilityRuleDefinitions.fixedFontSize,
            AccessibilityRuleDefinitions.smallTouchTarget,
            AccessibilityRuleDefinitions.colorOnlyInformation,
            AccessibilityRuleDefinitions.emptyAccessibilityMetadata,
            AccessibilityRuleDefinitions.hiddenInteractiveControl,
            AccessibilityRuleDefinitions.gestureOnlyInteraction,
            AccessibilityRuleDefinitions.restrictedDynamicType
        ]
        for rule in rules {
            let guide = RuleGuidance.forDiagnostic(diagnostic(rule))
            #expect(!guide.title.isEmpty)
            #expect(guide.title != rule.title)
            #expect(!guide.problem.isEmpty)
            #expect(!guide.impact.isEmpty)
            #expect(!guide.fix.isEmpty)
            #expect(!guide.before.isEmpty)
            #expect(!guide.after.isEmpty)
            #expect(!guide.verification.isEmpty)
            #expect(!guide.caveat.isEmpty)
        }
    }

    @Test("Guidance distinguishes visual alternatives and target-size standards")
    func avoidsMisleadingGuidance() {
        let targetGuide = RuleGuidance.forDiagnostic(diagnostic(AccessibilityRuleDefinitions.smallTouchTarget))
        #expect(targetGuide.caveat.contains("24 × 24 CSS px"))
        #expect(targetGuide.caveat.contains("exceções"))
        let colorGuide = RuleGuidance.forDiagnostic(diagnostic(AccessibilityRuleDefinitions.colorOnlyInformation))
        #expect(colorGuide.fix.contains("alternativa visual"))
        #expect(colorGuide.after.contains("Text(concluido"))
        #expect(HumanReportSupport.scopeNote.contains("nem certifica"))
        #expect(HumanReportSupport.scopeNote.contains("não garante acessibilidade"))
    }

    @Test("Empty metadata guidance identifies the actual modifier")
    func contextualEmptyMetadata() {
        for (name, description) in [
            ("accessibilityLabel", "Accessibility label must not be empty"),
            ("accessibilityHint", "Accessibility hint must not be empty"),
            ("accessibilityValue", "Accessibility value must not be empty")
        ] {
            let value = Diagnostic(
                rule: AccessibilityRuleDefinitions.emptyAccessibilityMetadata,
                description: description,
                filePath: "A.swift", line: 1, column: 2
            )
            let guide = RuleGuidance.forDiagnostic(value)
            #expect(guide.problem.contains(name))
            #expect(guide.before.contains(name))
        }
    }

    @Test("Unknown rules retain the diagnostic's original information")
    func futureRuleFallback() {
        let rule = customRule()
        let guide = RuleGuidance.forDiagnostic(diagnostic(rule))
        #expect(guide.title == rule.title)
        #expect(guide.problem == rule.description)
        #expect(guide.impact == rule.rationale)
        #expect(guide.fix == rule.suggestion)
        #expect(guide.before.isEmpty)
        #expect(guide.after.isEmpty)
    }

    @Test("Priority takes precedence over path while location remains exact")
    func priorityAndLocations() throws {
        let low = diagnostic(AccessibilityRuleDefinitions.colorOnlyInformation, path: "/work/App/A.swift", line: 4)
        let high = diagnostic(AccessibilityRuleDefinitions.missingLabel, path: "/work/App/Views/Meu Arquivo.swift", line: 23)
        let result = result([low, high])
        #expect(HumanReportSupport.orderedDiagnostics(result).map(\.ruleIdentifier) == ["SAC001", "SAC005"])
        for report in reporters() {
            let output = try report.render(result)
            #expect(output.contains("/work/App/Views/Meu Arquivo.swift:23:9"))
            #expect(output.contains("1. "))
            #expect(output.contains("Botão sem nome acessível claro"))
            #expect(output.range(of: "SAC001")!.lowerBound < output.range(of: "SAC005")!.lowerBound)
            #expect(output.contains("1970-01-01T00:00:00Z"))
        }
    }

    @Test("Relative display paths preserve directory boundaries")
    func safeDisplayPaths() {
        let result = result([])
        #expect(HumanReportSupport.displayPath("/work/App/Views/A.swift", in: result) == "Views/A.swift")
        #expect(HumanReportSupport.displayPath("/work/Application/A.swift", in: result) == "/work/Application/A.swift")
        let singleFileResult = AnalysisResult(inputPaths: ["/work/App/A.swift"], analyzedFiles: ["/work/App/A.swift"], diagnostics: [])
        #expect(HumanReportSupport.displayPath("/work/App/A.swift", in: singleFileResult) == "A.swift")
    }

    @Test("Explicit source arguments retain distinguishing directories")
    func sharedFileRoot() {
        let paths = ["/work/App/Account/View.swift", "/work/App/Settings/View.swift"]
        let result = AnalysisResult(inputPaths: paths, analyzedFiles: paths, diagnostics: [])
        #expect(HumanReportSupport.displayPath(paths[0], in: result) == "Account/View.swift")
        #expect(HumanReportSupport.displayPath(paths[1], in: result) == "Settings/View.swift")
        let directoryInputs = AnalysisResult(
            inputPaths: ["/work/App/Account", "/work/App/Settings"], analyzedFiles: paths, diagnostics: []
        )
        #expect(HumanReportSupport.displayPath(paths[0], in: directoryInputs) == "Account/View.swift")
        #expect(HumanReportSupport.displayPath(paths[1], in: directoryInputs) == "Settings/View.swift")
    }

    @Test("Disjoint roots stay identifiable")
    func disjointRoots() {
        let paths = ["/work/App/View.swift", "/tmp/App/View.swift"]
        let result = AnalysisResult(inputPaths: ["/work/App", "/tmp/App"], analyzedFiles: paths, diagnostics: [])
        #expect(HumanReportSupport.displayPath(paths[0], in: result) == paths[0])
        #expect(HumanReportSupport.displayPath(paths[1], in: result) == paths[1])
    }

    @Test("Large source lists do not overwhelm the report introduction")
    func compactInputSummary() throws {
        let paths = (1...50).map { "/work/App/Source\($0).swift" }
        let result = AnalysisResult(inputPaths: paths, analyzedFiles: paths, diagnostics: [])
        for reporter in reporters() {
            let output = try reporter.render(result)
            #expect(output.contains("mais 45 caminho(s)"))
            #expect(output.contains("lista completa"))
            #expect(!output.contains("/work/App/Source50.swift"))
        }
    }

    @Test("A successful empty scan and a scan with no files are different states")
    func emptyStates() throws {
        let clean = result([])
        let noFiles = AnalysisResult(inputPaths: ["/work/App"], analyzedFiles: [], diagnostics: [])
        for report in reporters() {
            let cleanOutput = try report.render(clean)
            let noFilesOutput = try report.render(noFiles)
            #expect(cleanOutput.contains("Nenhum achado nas regras executadas"))
            #expect(cleanOutput.contains("não garante acessibilidade"))
            #expect(noFilesOutput.contains("Nenhum arquivo Swift foi analisado"))
            #expect(!noFilesOutput.contains("Nenhum achado nas regras executadas"))
            #expect(noFilesOutput.contains("não permite avaliar"))
        }
    }

    @Test("Partial scans cannot look like a completed clean scan")
    func incompleteScan() throws {
        let result = AnalysisResult(
            inputPaths: ["/work/App"], analyzedFiles: ["/work/App/A.swift"], diagnostics: [],
            analysisIssues: [AnalysisIssue(filePath: "/work/App/B.swift", message: "Permissão negada", stage: "read")]
        )
        for report in reporters() {
            let output = try report.render(result)
            #expect(output.lowercased().contains("análise incompleta"))
            #expect(output.contains("/work/App/B.swift"))
            #expect(output.contains("Permissão negada"))
            #expect(output.contains("resultado permanece incompleto"))
            #expect(!output.contains("Nenhum achado nas regras executadas"))
        }
    }

    @Test("Actual numbered context is separate from illustrative examples")
    func sourceContextIsPreserved() throws {
        let value = diagnostic(AccessibilityRuleDefinitions.fixedFontSize, line: 100)
            .addingSourceExcerpt("SHOULD NOT REPLACE CONTEXT")
            .addingSourceContext([
                SourceContextLine(line: 99, text: "    Text(\"Olá\")"),
                SourceContextLine(line: 100, text: "        .font(.system(size: 16))"),
                SourceContextLine(line: 101, text: "")
            ])
        for report in reporters() {
            let output = try report.render(result([value]))
            #expect(output.contains("> 100 |         .font(.system(size: 16))"))
            #expect(output.contains("   99 |     Text(\"Olá\")"))
            #expect(!output.contains("SHOULD NOT REPLACE CONTEXT"))
            #expect(output.contains("exemplo ilustrativo"))
        }
    }

    @Test("Excerpt fallback and absent context are explicit")
    func excerptFallback() throws {
        let source = "    .font(.system(size: 12))"
        for report in reporters() {
            let withSource = try report.render(result([diagnostic(AccessibilityRuleDefinitions.fixedFontSize).addingSourceExcerpt(source)]))
            #expect(withSource.contains(source))
            let withoutSource = try report.render(result([diagnostic(AccessibilityRuleDefinitions.fixedFontSize)]))
            #expect(withoutSource.lowercased().contains("não disponível nesta execução"))
        }
    }

    @Test("Markdown safely contains arbitrary source fences and embedded HTML")
    func safeMarkdownFences() {
        let source = "let example = \"\"\"\n```\n<script>alert('example')</script>\n````\n\"\"\""
        let value = diagnostic(AccessibilityRuleDefinitions.fixedFontSize).addingSourceExcerpt(source)
        let output = MarkdownReporter().render(result([value]))
        #expect(output.contains("`````swift\n\(source)\n`````"))
    }

    @Test("Markdown escapes metadata and rejects executable reference links")
    func safeMarkdownMetadata() {
        let rule = customRule(
            title: "<img src=x> [bad](javascript:alert(1)) | text",
            references: [StandardReference(source: "Test", criterion: "Unsafe", url: "javascript:alert(1)")]
        )
        let output = MarkdownReporter().render(result([diagnostic(rule)]))
        #expect(!output.contains("<img"))
        #expect(output.contains("&lt;img src=x&gt;"))
        #expect(!output.contains("](<javascript:"))
        #expect(output.contains("\\| text"))
    }

    @Test("Markdown keeps official API URLs with parentheses usable")
    func safeOfficialReferenceLinks() {
        let output = MarkdownReporter().render(result([diagnostic(AccessibilityRuleDefinitions.missingLabel)]))
        #expect(output.contains("accessibilitylabel%28_:%29"))
        #expect(output.contains("https://www.w3.org/TR/WCAG22/#name-role-value"))
    }

    @Test("Text output remains plain text and includes usable reference URLs")
    func plainText() {
        let output = TextReporter().render(result([diagnostic(AccessibilityRuleDefinitions.fixedFontSize)]))
        #expect(!output.contains("```"))
        #expect(!output.contains("**"))
        #expect(!output.contains("\u{001B}"))
        #expect(output.contains("https://www.w3.org/TR/WCAG22/#resize-text"))
        #expect(output.contains("[ ] VoiceOver"))
    }

    private func reporters() -> [any AnalysisReporter] {
        [MarkdownReporter(), TextReporter()]
    }

    private func diagnostic(
        _ rule: AccessibilityRuleDefinition,
        path: String = "/work/App/View.swift",
        line: Int = 7
    ) -> Diagnostic {
        Diagnostic(rule: rule, filePath: path, line: line, column: 9)
    }

    private func result(_ diagnostics: [Diagnostic]) -> AnalysisResult {
        AnalysisResult(
            generatedAt: Date(timeIntervalSince1970: 0),
            inputPaths: ["/work/App"],
            analyzedFiles: diagnostics.isEmpty ? ["/work/App/View.swift"] : Array(Set(diagnostics.map(\.filePath))),
            diagnostics: diagnostics
        )
    }

    private func customRule(title: String = "Future rule", references: [StandardReference] = []) -> AccessibilityRuleDefinition {
        AccessibilityRuleDefinition(
            identifier: "SAC999", title: title, description: "Future problem", severity: .low,
            rationale: "Future impact", suggestion: "Future fix", references: references
        )
    }
}
