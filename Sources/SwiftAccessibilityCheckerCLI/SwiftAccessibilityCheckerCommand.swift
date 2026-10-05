import Darwin
import Foundation
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter

@main
enum SwiftAccessibilityCheckerCommand {
    static func main() {
        exit(run(arguments: Array(CommandLine.arguments.dropFirst())))
    }

    private static func run(arguments: [String]) -> Int32 {
        if arguments == ["--help"] || arguments == ["-h"] {
            print(CommandOptions.usage)
            return 0
        }

        let options: CommandOptions
        do {
            options = try CommandOptions(arguments: arguments)
        } catch {
            writeError("error: \(error.localizedDescription)")
            writeError(CommandOptions.usage)
            return 64
        }

        let run = ProjectAnalysisRunner().run(inputPaths: options.inputPaths)
        let result = run.result
        let discoveredFiles = run.discoveredFiles

        for issue in result.analysisIssues ?? [] {
            writeError("\(issue.filePath): error: Não foi possível analisar: \(issue.message)")
        }

        do {
            // A single analysis feeds every format so dates, counts and locations agree.
            if let directory = options.reportDirectory {
                let index = try ReportBundleWriter().write(result, to: URL(fileURLWithPath: directory))
                writeError("SwiftAccessibilityChecker: relatório disponível em \(index.path)")
            }
            let output = try options.format.reporter.render(result)
            try writeOutput(output, to: options.outputPath, inputs: discoveredFiles)
        } catch {
            writeError("error: Não foi possível gerar o relatório: \(error.localizedDescription)")
            return 74
        }

        if !run.invalidInputPaths.isEmpty { return 66 }
        return (result.analysisIssues ?? []).isEmpty ? 0 : 1
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }

    private static func writeOutput(_ output: String, to outputPath: String?, inputs: [URL]) throws {
        if let outputPath {
            let url = URL(fileURLWithPath: outputPath).standardizedFileURL
            guard !inputs.contains(where: {
                $0.resolvingSymlinksInPath() == url.resolvingSymlinksInPath()
            }) else { throw CommandOptionsError.outputIsInput }
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let text = output.isEmpty ? "" : "\(output)\n"
            try Data(text.utf8).write(to: url, options: .atomic)
        } else if !output.isEmpty {
            FileHandle.standardOutput.write(Data("\(output)\n".utf8))
        }
    }
}

private struct CommandOptions {
    static let usage = """
        Swift Accessibility Checker — relatórios de acessibilidade SwiftUI

        Uso: swift-accessibility-checker [opções] <arquivo-ou-pasta> [...]

        --report-directory <pasta>  Gera report.html, report.md, report.txt,
                                    report.json e warnings.txt em uma única análise.
        --format <formato>           xcode (padrão), json, html, markdown ou text.
        --output <arquivo>           Salva o formato escolhido; cria pastas necessárias.
        --help, -h                  Exibe esta ajuda.
        --                          Encerra opções (para caminhos iniciados por hífen).

        Exemplo:
          swift-accessibility-checker --report-directory Relatorios Sources
          open Relatorios/report.html

        Os avisos não interrompem o build. Falhas de leitura/análise retornam erro
        e aparecem nos relatórios. Zero avisos não certifica acessibilidade.
        """

    let inputPaths: [String]
    let format: ReportFormat
    let outputPath: String?
    let reportDirectory: String?

    init(arguments: [String]) throws {
        var inputPaths: [String] = []
        var format = ReportFormat.xcode
        var outputPath: String?
        var reportDirectory: String?
        var index = 0
        var positionalOnly = false

        func value(for option: String) throws -> String {
            guard index + 1 < arguments.count,
                  !arguments[index + 1].isEmpty,
                  !arguments[index + 1].hasPrefix("--") else {
                throw CommandOptionsError.missingValue(option)
            }
            index += 1
            return arguments[index]
        }

        while index < arguments.count {
            let argument = arguments[index]
            if positionalOnly {
                inputPaths.append(argument)
            } else {
                switch argument {
                case "--": positionalOnly = true
                case "--format": format = try ReportFormat(argument: value(for: argument))
                case "--output": outputPath = try value(for: argument)
                case "--report-directory": reportDirectory = try value(for: argument)
                case let option where option.hasPrefix("--format="):
                    format = try ReportFormat(argument: String(option.dropFirst("--format=".count)))
                case let option where option.hasPrefix("--output="):
                    outputPath = String(option.dropFirst("--output=".count))
                case let option where option.hasPrefix("--report-directory="):
                    reportDirectory = String(option.dropFirst("--report-directory=".count))
                case let option where option.hasPrefix("-"):
                    throw CommandOptionsError.unknownOption(option)
                default: inputPaths.append(argument)
                }
            }
            index += 1
        }

        if outputPath?.isEmpty == true { throw CommandOptionsError.missingValue("--output") }
        if reportDirectory?.isEmpty == true { throw CommandOptionsError.missingValue("--report-directory") }
        guard !inputPaths.isEmpty else { throw CommandOptionsError.missingInput }
        if let outputPath, let reportDirectory {
            let output = URL(fileURLWithPath: outputPath).standardizedFileURL.resolvingSymlinksInPath()
            let directory = URL(fileURLWithPath: reportDirectory).standardizedFileURL.resolvingSymlinksInPath()
            if ReportBundleWriter.fileNames.contains(where: {
                directory.appendingPathComponent($0).resolvingSymlinksInPath() == output
            }) { throw CommandOptionsError.conflictingOutput }
        }

        self.inputPaths = inputPaths
        self.format = format
        self.outputPath = outputPath
        self.reportDirectory = reportDirectory
    }
}

private enum ReportFormat: String {
    case xcode, json, html, markdown, text

    init(argument: String) throws {
        guard let format = Self(rawValue: argument.lowercased()) else {
            throw CommandOptionsError.invalidFormat(argument)
        }
        self = format
    }

    var reporter: any AnalysisReporter {
        switch self {
        case .xcode: XcodeReporter()
        case .json: JSONReporter()
        case .html: HTMLReporter()
        case .markdown: MarkdownReporter()
        case .text: TextReporter()
        }
    }
}

private enum CommandOptionsError: LocalizedError {
    case missingInput, outputIsInput, conflictingOutput
    case missingValue(String), invalidFormat(String), unknownOption(String)

    var errorDescription: String? {
        switch self {
        case .missingInput: "Informe ao menos um arquivo Swift ou uma pasta"
        case .missingValue(let option): "Falta o valor da opção: \(option)"
        case .invalidFormat(let format): "Formato não suportado: \(format)"
        case .unknownOption(let option): "Opção desconhecida: \(option)"
        case .outputIsInput: "O relatório não pode substituir um arquivo Swift analisado"
        case .conflictingOutput: "--output não pode substituir um dos arquivos de --report-directory"
        }
    }
}
