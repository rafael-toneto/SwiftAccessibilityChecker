import Foundation
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter
import Testing

@Suite("HTML report for development teams")
struct HTMLReporterTests {
    @Test("Escapes source, paths, metadata and reference labels without creating executable markup")
    func escapesUntrustedContent() {
        let attack = "</script><script>alert('source')</script><img src=x onerror=alert(1)>"
        let path = "/project/\" onmouseover=\"alert(1)/A<&>.swift"
        let rule = AccessibilityRuleDefinition(
            identifier: "CUSTOM\" data-x=\"injected",
            title: attack,
            description: attack,
            severity: .high,
            rationale: attack,
            suggestion: attack,
            references: [
                StandardReference(source: attack, criterion: attack, url: "javascript:alert(1)"),
                StandardReference(source: "Unsafe", criterion: "Data URL", url: "data:text/html,test"),
                StandardReference(source: "Unsafe", criterion: "Relative URL", url: "//example.org/spec"),
                StandardReference(source: "Unsafe", criterion: "Credentials", url: "https://user:pass@example.org/spec"),
                StandardReference(source: "Safe", criterion: "Spec", url: "https://example.org/spec?a=1&b=2")
            ]
        )
        let diagnostic = Diagnostic(rule: rule, filePath: path, line: 3, column: 4, sourceExcerpt: attack)
        let output = HTMLReporter().render(result([diagnostic], files: [path]))

        #expect(!output.contains(attack))
        #expect(output.contains("&lt;/script&gt;&lt;script&gt;alert(&#39;source&#39;)&lt;/script&gt;"))
        #expect(output.contains("&quot; onmouseover=&quot;alert(1)/A&lt;&amp;&gt;.swift"))
        #expect(!output.contains("href=\"javascript:"))
        #expect(!output.contains("href=\"data:"))
        #expect(!output.contains("href=\"//example.org"))
        #expect(!output.contains("href=\"https://user:pass@"))
        #expect(output.contains("href=\"https://example.org/spec?a=1&amp;b=2\""))
        #expect(output.components(separatedBy: "<script>").count == 2)
        #expect(output.components(separatedBy: "</script>").count == 2)
        #expect(!output.contains("<img src="))
    }

    @Test("Orders actionable findings by priority and retains exact source locations")
    func prioritizesAndLocatesFindings() throws {
        let low = diagnostic(.colorOnlyInformation, path: "/project/A.swift", line: 1)
        let medium = diagnostic(.fixedFontSize, path: "/project/B.swift", line: 4)
        let high = diagnostic(.missingLabel, path: "/project/Z.swift", line: 22)
        let output = HTMLReporter().render(result([medium, low, high]))

        let highPosition = try #require(output.range(of: "data-rule=\"SAC001\""))
        let mediumPosition = try #require(output.range(of: "data-rule=\"SAC003\""))
        let lowPosition = try #require(output.range(of: "data-rule=\"SAC005\""))
        #expect(highPosition.lowerBound < mediumPosition.lowerBound)
        #expect(mediumPosition.lowerBound < lowPosition.lowerBound)
        #expect(output.contains("/project/Z.swift:22:9"))
        #expect(output.contains("linha 22, coluna 9"))
        #expect(output.contains("Por que ajustar"))
        #expect(output.contains("Como ajustar"))
        #expect(output.contains("Como confirmar no app"))
        #expect(output.contains("Copiar para uma tarefa"))
        #expect(output.contains("Ilustrativo · adapte ao seu código"))
    }

    @Test("Renders numbered surrounding code and marks the finding without losing indentation")
    func rendersSourceContext() {
        let finding = diagnostic(.missingLabel, path: "/project/View.swift", line: 12)
            .addingSourceContext([
                SourceContextLine(line: 11, text: "    HStack {"),
                SourceContextLine(line: 12, text: "        Button { print(\"<test>\") }"),
                SourceContextLine(line: 13, text: "    }")
            ])
        let output = HTMLReporter().render(result([finding]))

        #expect(output.contains("› marca a linha 12"))
        #expect(output.contains("class=\"source-line source-current\">› 12 │         Button"))
        #expect(output.contains("  11 │     HStack {"))
        #expect(output.contains("&quot;&lt;test&gt;&quot;"))
        #expect(output.contains("&gt; 12 |         Button"))
    }

    @Test("Distinguishes a successful scan without findings from no analysis")
    func differentiatesEmptyStates() {
        let analyzed = HTMLReporter().render(result([], files: ["/project/View.swift"]))
        let notAnalyzed = HTMLReporter().render(result([], files: []))

        #expect(analyzed.contains("Nenhuma ocorrência nas regras verificadas"))
        #expect(analyzed.contains("A ausência de avisos não garante acessibilidade"))
        #expect(!analyzed.contains("<h2>Nenhum arquivo foi analisado</h2>"))
        #expect(notAnalyzed.contains("Nenhum arquivo foi analisado"))
        #expect(notAnalyzed.contains("Confira os caminhos de entrada"))
        #expect(!notAnalyzed.contains("Nenhuma ocorrência nas regras verificadas"))
        #expect(analyzed.contains("Validação manual"))
        #expect(notAnalyzed.contains("Validação manual"))
    }

    @Test("Incomplete scans always report coverage problems, including total failure")
    func reportsIncompleteAnalysis() {
        for files in [["/project/Good.swift"], []] {
            let analysis = AnalysisResult(
                generatedAt: Date(timeIntervalSince1970: 0),
                inputPaths: ["/project"],
                analyzedFiles: files,
                diagnostics: [],
                analysisIssues: [AnalysisIssue(filePath: "/project/<bad>.swift", message: "Permission <denied>", stage: "read")]
            )
            let output = HTMLReporter().render(analysis)
            #expect(output.contains("<h2>Análise incompleta</h2>"))
            #expect(output.contains("Atenção à cobertura: análise incompleta"))
            #expect(output.contains("/project/&lt;bad&gt;.swift"))
            #expect(output.contains("Permission &lt;denied&gt;"))
            #expect(!output.contains("Nenhuma ocorrência nas regras verificadas"))
        }
    }

    @Test("Produces stable self-contained HTML and leaves findings visible before JavaScript")
    func isDeterministicAndProgressivelyEnhanced() {
        let a = diagnostic(.fixedFontSize, path: "/project/A.swift", line: 8)
        let b = diagnostic(.missingLabel, path: "/project/B.swift", line: 2)
        let output = HTMLReporter().render(result([a, b], files: [b.filePath, a.filePath]))
        let reordered = HTMLReporter().render(result([b, a], files: [a.filePath, b.filePath]))

        #expect(output == reordered)
        #expect(output.contains("<html lang=\"pt-BR\">"))
        #expect(output.contains("<noscript>"))
        #expect(!output.contains("<script src="))
        #expect(!output.contains("<link rel=\"stylesheet\""))
        #expect(!output.contains("fetch("))
        #expect(output.contains("@media print"))
        #expect(output.contains("navigator.clipboard.writeText"))
        #expect(output.contains("document.execCommand('copy')"))
        #expect(output.contains("id=\"copy-dialog\""))
        let articles = output.components(separatedBy: "<article ").dropFirst()
        #expect(articles.count == 2)
        for article in articles {
            let openingTag = article.split(separator: ">", maxSplits: 1)[0]
            #expect(!openingTag.contains("hidden"))
        }
    }

    @Test("Unknown rules keep their guidance and do not produce empty example panels")
    func handlesUnknownRules() {
        let rule = AccessibilityRuleDefinition(
            identifier: "CUSTOM001", title: "Regra do projeto", description: "Confira o comportamento.",
            severity: .low, rationale: "Pode impedir uma ação.", suggestion: "Revise o controle.", references: []
        )
        let finding = Diagnostic(rule: rule, filePath: "View.swift", line: 1, column: 1)
        let output = HTMLReporter().render(result([finding]))
        #expect(output.contains("Regra do projeto"))
        #expect(output.contains("Revise o controle."))
        #expect(output.contains("Trecho indisponível"))
        #expect(!output.contains("<div class=\"examples\">"))
    }

    private func result(_ diagnostics: [Diagnostic], files: [String]? = nil) -> AnalysisResult {
        AnalysisResult(
            generatedAt: Date(timeIntervalSince1970: 0), inputPaths: ["/project"],
            analyzedFiles: files ?? Array(Set(diagnostics.map(\.filePath))), diagnostics: diagnostics
        )
    }

    private func diagnostic(_ rule: AccessibilityRuleDefinition, path: String, line: Int) -> Diagnostic {
        Diagnostic(rule: rule, filePath: path, line: line, column: 9, sourceExcerpt: "Button { action() }")
    }
}

private extension AccessibilityRuleDefinition {
    static var missingLabel: Self { AccessibilityRuleDefinitions.missingLabel }
    static var fixedFontSize: Self { AccessibilityRuleDefinitions.fixedFontSize }
    static var colorOnlyInformation: Self { AccessibilityRuleDefinitions.colorOnlyInformation }
}
