import Foundation
import SwiftAccessibilityCheckerCore

public enum HumanReportSupport {
    public static let scopeNote = "Esta análise estática identifica padrões de risco no código SwiftUI; não executa o app nem certifica conformidade com todas as diretrizes Apple ou WCAG. Os achados precisam de revisão no contexto da interface. A ausência de avisos não garante acessibilidade."

    public static let manualChecks = [
        "VoiceOver: percorra os fluxos principais e confira nomes, estados, ordem de foco, agrupamento e anúncios de mudanças.",
        "Dynamic Type: teste os maiores tamanhos de acessibilidade, textos longos e os idiomas suportados, sem cortes ou sobreposição.",
        "Contraste e cor: confira textos, ícones e estados nos temas claro e escuro; toda informação por cor também precisa de outro indicador.",
        "Interação: valide áreas de toque, teclado, Controle por Voz e Controle Assistivo nos dispositivos e plataformas suportados.",
        "Movimento e mídia: respeite Reduzir Movimento e revise legendas, transcrições e alternativas para conteúdo audiovisual quando houver.",
        "Validação: execute o Accessibility Inspector, registre os resultados e teste os fluxos com pessoas que usam tecnologias assistivas."
    ]

    public static func severityLabel(_ severity: DiagnosticSeverity) -> String {
        switch severity {
        case .high: "Alta"
        case .medium: "Média"
        case .low: "Baixa"
        }
    }

    public static func priorityRank(_ severity: DiagnosticSeverity) -> Int {
        switch severity {
        case .high: 0
        case .medium: 1
        case .low: 2
        }
    }

    /// Uses a shared root so files with identical names stay distinguishable.
    /// Detail views always keep the original path.
    public static func displayPath(_ path: String, in result: AnalysisResult) -> String {
        let target = URL(fileURLWithPath: path).standardizedFileURL.path
        let files = result.analyzedFiles.map { URL(fileURLWithPath: $0).standardizedFileURL.path }
        let candidates = result.inputPaths.compactMap { input -> String? in
            let root = URL(fileURLWithPath: input).standardizedFileURL.path
            let prefix = root == "/" ? "/" : root + "/"
            guard root != "/", target.hasPrefix(prefix), target != root,
                  files.allSatisfy({ $0.hasPrefix(prefix) })
            else { return nil }
            return String(target.dropFirst(prefix.count))
        }
        if let candidate = candidates.min(by: { ($0.count, $0) < ($1.count, $1) }) {
            return candidate
        }

        let parents = files.map { URL(fileURLWithPath: $0).deletingLastPathComponent().pathComponents }
        guard var common = parents.first else { return path }
        for parent in parents.dropFirst() {
            common = Array(zip(common, parent).prefix { $0 == $1 }.map(\.0))
        }
        // A root-only common ancestor would obscure that the files are unrelated.
        guard common.count > 1 else { return path }
        let root = NSString.path(withComponents: common)
        let prefix = root + "/"
        guard target.hasPrefix(prefix) else { return path }
        return String(target.dropFirst(prefix.count))
    }

    public static func orderedDiagnostics(_ result: AnalysisResult) -> [Diagnostic] {
        result.diagnostics.sorted {
            let left = (priorityRank($0.severity), $0.filePath, $0.line, $0.column, $0.ruleIdentifier)
            let right = (priorityRank($1.severity), $1.filePath, $1.line, $1.column, $1.ruleIdentifier)
            return left < right
        }
    }

    static func generatedAt(_ result: AnalysisResult) -> String {
        ISO8601DateFormatter().string(from: result.generatedAt)
    }

    static func location(_ diagnostic: Diagnostic) -> String {
        "\(diagnostic.filePath):\(diagnostic.line):\(diagnostic.column)"
    }

    static func sourceSnippet(_ diagnostic: Diagnostic) -> String? {
        if let context = diagnostic.sourceContext, !context.isEmpty {
            let width = context.map { String($0.line).count }.max() ?? 1
            return context.map { item in
                let marker = item.line == diagnostic.line ? ">" : " "
                let number = String(item.line)
                let padding = String(repeating: " ", count: max(0, width - number.count))
                return "\(marker) \(padding)\(number) | \(item.text)"
            }.joined(separator: "\n")
        }
        guard let source = diagnostic.sourceExcerpt, !source.isEmpty else { return nil }
        return source
    }

    static func severitySummary(_ result: AnalysisResult) -> String {
        [DiagnosticSeverity.high, .medium, .low].map {
            "\(severityLabel($0)): \(result.summary.bySeverity[$0.rawValue, default: 0])"
        }.joined(separator: " · ")
    }

    static func prioritizedRules(_ result: AnalysisResult) -> [(diagnostic: Diagnostic, count: Int)] {
        let groups = Dictionary(grouping: orderedDiagnostics(result), by: \.ruleIdentifier)
        return groups.compactMap { _, diagnostics in
            diagnostics.first.map { (diagnostic: $0, count: diagnostics.count) }
        }.sorted {
            (priorityRank($0.diagnostic.severity), -$0.count, $0.diagnostic.ruleIdentifier)
                < (priorityRank($1.diagnostic.severity), -$1.count, $1.diagnostic.ruleIdentifier)
        }
    }

    static func prioritizedFiles(_ result: AnalysisResult) -> [(path: String, count: Int)] {
        Dictionary(grouping: result.diagnostics, by: \.filePath)
            .map { (path: $0.key, count: $0.value.count) }
            .sorted { (-$0.count, $0.path) < (-$1.count, $1.path) }
    }
}

enum MarkdownFormatting {
    static func text(_ value: String) -> String {
        let htmlSafe = value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        var result = ""
        for character in htmlSafe {
            if "\\`*_{}[]()#+.!|-".contains(character) { result.append("\\") }
            result.append(character == "\n" || character == "\r" ? " " : character)
        }
        return result
    }

    /// A longer delimiter prevents source containing Markdown fences from breaking the report.
    static func code(_ value: String, language: String = "") -> String {
        var longest = 0
        var current = 0
        for character in value {
            current = character == "`" ? current + 1 : 0
            longest = max(longest, current)
        }
        let fence = String(repeating: "`", count: max(3, longest + 1))
        return "\(fence)\(language)\n\(value)\n\(fence)"
    }

    static func reference(_ reference: StandardReference) -> String {
        let label = text("\(reference.source) — \(reference.criterion)")
        guard let url = URL(string: reference.url),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil
        else {
            return "\(label): \(text(reference.url))"
        }
        // Percent-encode angle brackets and parentheses so a URL cannot end the link.
        let destination = url.absoluteString
            .replacingOccurrences(of: "<", with: "%3C")
            .replacingOccurrences(of: ">", with: "%3E")
            .replacingOccurrences(of: "(", with: "%28")
            .replacingOccurrences(of: ")", with: "%29")
        return "[\(label)](<\(destination)>)"
    }
}
