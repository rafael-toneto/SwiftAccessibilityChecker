import SwiftAccessibilityCheckerCore

/// A portable report suitable for pull requests, issue trackers and documentation.
public struct MarkdownReporter: AnalysisReporter {
    public init() {}

    public func render(_ result: AnalysisResult) -> String {
        let diagnostics = HumanReportSupport.orderedDiagnostics(result)
        let issues = result.analysisIssues ?? []
        let affectedFiles = Set(diagnostics.map(\.filePath)).count
        var sections = [
            "# Relatório de acessibilidade",
            "Swift Accessibility Checker · Gerado em \(HumanReportSupport.generatedAt(result))",
            "## Resumo",
            "**\(diagnostics.count) achado(s) para revisar** em **\(affectedFiles) arquivo(s)**. Arquivos Swift analisados: **\(result.analyzedFiles.count)**.",
            "\(HumanReportSupport.severitySummary(result)).",
            "> \(HumanReportSupport.scopeNote)"
        ]

        if !issues.isEmpty {
            sections.append("### Análise incompleta")
            sections.append("**Há arquivos ou caminhos que não puderam ser analisados. Corrija os erros abaixo e execute novamente antes de concluir a revisão.**")
            for issue in issues {
                sections.append(MarkdownFormatting.code(issue.filePath))
                sections.append(MarkdownFormatting.text(issue.message))
            }
        }

        if result.analyzedFiles.isEmpty {
            sections.append("**Nenhum arquivo Swift foi analisado.** Confira os caminhos de entrada, as exclusões e a configuração do plugin. Este resultado não permite avaliar o código do projeto.")
        } else if diagnostics.isEmpty {
            sections.append(issues.isEmpty
                ? "**Nenhum achado nas regras executadas.** Continue com a validação manual ao final deste relatório."
                : "**Nenhum achado nos arquivos que puderam ser analisados.** O resultado permanece incompleto pelos erros listados acima.")
        }

        sections.append("### Escopo da execução")
        sections.append("Caminhos de entrada:")
        sections.append(result.inputPaths.isEmpty
            ? "Nenhum caminho de entrada informado."
            : result.inputPaths.prefix(5).map { MarkdownFormatting.code($0) }.joined(separator: "\n\n"))
        if result.inputPaths.count > 5 {
            sections.append("… e mais \(result.inputPaths.count - 5) caminho(s). O formato JSON contém a lista completa de entradas e arquivos analisados.")
        }

        if !diagnostics.isEmpty {
            sections.append("## Por onde começar")
            sections.append("Revise os itens de prioridade **alta** primeiro. A prioridade estima o possível impacto; ela não é um nível de conformidade WCAG. Confirme o contexto, aplique a correção e valide no app. Mais de uma regra pode apontar para o mesmo componente.")
            sections.append(ruleTable(result))
            sections.append("### Arquivos com achados")
            sections.append(fileTable(result))
            sections.append("## Ajustes no código")
            sections.append("As ocorrências estão ordenadas por prioridade, arquivo e posição. Os exemplos são **ilustrativos**: adapte nomes, estados, localização e layout ao projeto. O trecho encontrado é mostrado separadamente.")
            for (index, diagnostic) in diagnostics.enumerated() {
                sections.append(detail(diagnostic, number: index + 1, result: result))
            }
        }

        sections.append("## Validação manual que complementa este relatório")
        sections.append(HumanReportSupport.manualChecks.map { "- [ ] \($0)" }.joined(separator: "\n"))
        sections.append("Depois dos ajustes, execute o checker novamente e registre a validação manual no PR. Para um possível falso positivo, registre a regra, o trecho e o comportamento observado; remova dados sensíveis antes de compartilhar.")
        return sections.joined(separator: "\n\n") + "\n"
    }

    private func ruleTable(_ result: AnalysisResult) -> String {
        let rows = HumanReportSupport.prioritizedRules(result).map { row in
            let guidance = RuleGuidance.forDiagnostic(row.diagnostic)
            return "| \(HumanReportSupport.severityLabel(row.diagnostic.severity)) | \(MarkdownFormatting.text(row.diagnostic.ruleIdentifier)) | \(MarkdownFormatting.text(guidance.title)) | \(row.count) |"
        }
        return (["| Prioridade | Regra | O que revisar | Ocorrências |", "| --- | --- | --- | ---: |"] + rows)
            .joined(separator: "\n")
    }

    private func fileTable(_ result: AnalysisResult) -> String {
        let rows = HumanReportSupport.prioritizedFiles(result).map { row in
            "| \(MarkdownFormatting.text(HumanReportSupport.displayPath(row.path, in: result))) | \(row.count) |"
        }
        return (["| Arquivo | Ocorrências |", "| --- | ---: |"] + rows).joined(separator: "\n")
    }

    private func detail(_ diagnostic: Diagnostic, number: Int, result: AnalysisResult) -> String {
        let guidance = RuleGuidance.forDiagnostic(diagnostic)
        let path = HumanReportSupport.displayPath(diagnostic.filePath, in: result)
        var parts = [
            "### \(number). \(MarkdownFormatting.text(guidance.title))",
            "**Prioridade \(HumanReportSupport.severityLabel(diagnostic.severity))** · \(MarkdownFormatting.text(diagnostic.ruleIdentifier)) · \(MarkdownFormatting.text(path)) · linha **\(diagnostic.line)**, coluna **\(diagnostic.column)**",
            "**Localização original para abrir no editor:**",
            MarkdownFormatting.code(HumanReportSupport.location(diagnostic)),
            "**O que foi encontrado:** \(MarkdownFormatting.text(guidance.problem))",
            "**Impacto para quem usa o app:** \(MarkdownFormatting.text(guidance.impact))",
            "**Como ajustar:** \(MarkdownFormatting.text(guidance.fix))"
        ]
        if let source = HumanReportSupport.sourceSnippet(diagnostic) {
            let hasContext = !(diagnostic.sourceContext ?? []).isEmpty
            let label = hasContext ? "Trecho encontrado (linha apontada marcada com >):" : "Trecho encontrado:"
            parts.append("**\(label)**\n\n\(MarkdownFormatting.code(source, language: hasContext ? "text" : "swift"))")
        } else {
            parts.append("**Trecho encontrado:** não disponível nesta execução. Abra a localização acima para revisar o contexto.")
        }
        if !guidance.before.isEmpty {
            parts.append("**Antes — exemplo ilustrativo:**\n\n\(MarkdownFormatting.code(guidance.before, language: "swift"))")
        }
        if !guidance.after.isEmpty {
            parts.append("**Depois — exemplo ilustrativo:**\n\n\(MarkdownFormatting.code(guidance.after, language: "swift"))")
        }
        parts.append("**Como validar:** \(MarkdownFormatting.text(guidance.verification))")
        parts.append("**Antes de concluir:** \(MarkdownFormatting.text(guidance.caveat))")
        if !diagnostic.references.isEmpty {
            parts.append("**Referências:**\n\n" + diagnostic.references.map {
                "- \(MarkdownFormatting.reference($0))"
            }.joined(separator: "\n"))
        }
        return parts.joined(separator: "\n\n")
    }
}
