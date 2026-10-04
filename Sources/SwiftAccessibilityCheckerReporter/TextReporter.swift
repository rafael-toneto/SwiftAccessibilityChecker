import SwiftAccessibilityCheckerCore

/// Plain text without terminal color codes or Markdown markup.
public struct TextReporter: AnalysisReporter {
    public init() {}

    public func render(_ result: AnalysisResult) -> String {
        let diagnostics = HumanReportSupport.orderedDiagnostics(result)
        let issues = result.analysisIssues ?? []
        var lines = [
            "RELATÓRIO DE ACESSIBILIDADE",
            "Swift Accessibility Checker",
            "Gerado em: \(HumanReportSupport.generatedAt(result))",
            "",
            "RESUMO",
            "\(diagnostics.count) achado(s) para revisar em \(Set(diagnostics.map(\.filePath)).count) arquivo(s).",
            "Arquivos Swift analisados: \(result.analyzedFiles.count)",
            HumanReportSupport.severitySummary(result),
            "",
            HumanReportSupport.scopeNote
        ]

        if !issues.isEmpty {
            lines += ["", "ANÁLISE INCOMPLETA", "Há caminhos ou arquivos que não puderam ser analisados. Corrija os erros e execute novamente:"]
            for issue in issues {
                lines += ["- \(issue.filePath)", "  \(issue.message)"]
            }
        }
        if result.analyzedFiles.isEmpty {
            lines += ["", "Nenhum arquivo Swift foi analisado. Confira caminhos, exclusões e a configuração do plugin. Este resultado não permite avaliar o código do projeto."]
        } else if diagnostics.isEmpty {
            lines += ["", issues.isEmpty
                ? "Nenhum achado nas regras executadas. Continue com a validação manual abaixo."
                : "Nenhum achado nos arquivos que puderam ser analisados. O resultado permanece incompleto pelos erros acima."]
        }

        lines += ["", "CAMINHOS DE ENTRADA"]
        lines += result.inputPaths.isEmpty ? ["Nenhum caminho informado."] : result.inputPaths.prefix(5).map { "- \($0)" }
        if result.inputPaths.count > 5 {
            lines.append("… e mais \(result.inputPaths.count - 5) caminho(s). O formato JSON contém a lista completa de entradas e arquivos analisados.")
        }

        if !diagnostics.isEmpty {
            lines += [
                "", "POR ONDE COMEÇAR",
                "Revise os itens de prioridade alta primeiro. A prioridade estima o possível impacto; não é um nível de conformidade WCAG.",
                "Confirme o contexto, ajuste o código e valide no app. Mais de uma regra pode apontar para o mesmo componente.",
                ""
            ]
            for row in HumanReportSupport.prioritizedRules(result) {
                lines.append("- \(HumanReportSupport.severityLabel(row.diagnostic.severity)) | \(row.diagnostic.ruleIdentifier) | \(RuleGuidance.forDiagnostic(row.diagnostic).title) | \(row.count) ocorrência(s)")
            }
            lines += ["", "ARQUIVOS COM ACHADOS"]
            for row in HumanReportSupport.prioritizedFiles(result) {
                lines.append("- \(HumanReportSupport.displayPath(row.path, in: result)): \(row.count) ocorrência(s)")
            }
            lines += ["", "AJUSTES NO CÓDIGO", "Exemplos ilustrativos: adapte nomes, estados, localização e layout ao projeto."]
            for (index, diagnostic) in diagnostics.enumerated() {
                lines += detail(diagnostic, number: index + 1, result: result)
            }
        }

        lines += ["", "VALIDAÇÃO MANUAL QUE COMPLEMENTA ESTE RELATÓRIO"]
        lines += HumanReportSupport.manualChecks.map { "[ ] \($0)" }
        lines += ["", "Execute o checker novamente após os ajustes e registre a validação manual no PR. Para um possível falso positivo, registre a regra, o trecho e o comportamento observado; remova dados sensíveis antes de compartilhar."]
        return lines.joined(separator: "\n") + "\n"
    }

    private func detail(_ diagnostic: Diagnostic, number: Int, result: AnalysisResult) -> [String] {
        let guidance = RuleGuidance.forDiagnostic(diagnostic)
        var lines = [
            "", String(repeating: "─", count: 64),
            "\(number). [\(HumanReportSupport.severityLabel(diagnostic.severity))] \(guidance.title) (\(diagnostic.ruleIdentifier))",
            "Arquivo: \(HumanReportSupport.displayPath(diagnostic.filePath, in: result))",
            "Linha: \(diagnostic.line) | Coluna: \(diagnostic.column)",
            "Localização original: \(HumanReportSupport.location(diagnostic))",
            "", "O que foi encontrado: \(guidance.problem)",
            "Impacto para quem usa o app: \(guidance.impact)",
            "Como ajustar: \(guidance.fix)",
            "", !(diagnostic.sourceContext ?? []).isEmpty
                ? "Trecho encontrado (linha apontada marcada com >):"
                : "Trecho encontrado:"
        ]
        if let source = HumanReportSupport.sourceSnippet(diagnostic) {
            lines += indented(source)
        } else {
            lines.append("  Não disponível nesta execução. Abra a localização acima para revisar o contexto.")
        }
        if !guidance.before.isEmpty {
            lines += ["", "Antes — exemplo ilustrativo:"] + indented(guidance.before)
        }
        if !guidance.after.isEmpty {
            lines += ["", "Depois — exemplo ilustrativo:"] + indented(guidance.after)
        }
        lines += ["", "Como validar: \(guidance.verification)", "Antes de concluir: \(guidance.caveat)"]
        if !diagnostic.references.isEmpty {
            lines += ["", "Referências:"]
            lines += diagnostic.references.map { "- \($0.source) — \($0.criterion): \($0.url)" }
        }
        return lines
    }

    private func indented(_ value: String) -> [String] {
        value.split(separator: "\n", omittingEmptySubsequences: false).map { "  \($0)" }
    }
}
