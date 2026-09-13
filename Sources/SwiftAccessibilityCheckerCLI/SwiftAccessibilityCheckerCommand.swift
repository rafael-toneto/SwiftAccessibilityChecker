import Darwin
import Foundation
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter

@main
enum SwiftAccessibilityCheckerCommand {
    static func main() {
        let exitCode = run(arguments: Array(CommandLine.arguments.dropFirst()))
        exit(exitCode)
    }

    private static func run(arguments: [String]) -> Int32 {
        let options: CommandOptions
        do {
            options = try CommandOptions(arguments: arguments)
        } catch {
            writeError("error: \(error.localizedDescription)")
            writeError(CommandOptions.usage)
            return 64
        }

        let discoverer = SwiftFileDiscoverer()
        var discoveredFilesByPath: [String: URL] = [:]
        var discoveryIssues: [FileDiscoveryIssue] = []

        for inputPath in options.inputPaths {
            do {
                let discovery = try discoverer.discover(at: inputPath)
                discovery.files.forEach { discoveredFilesByPath[$0.path] = $0 }
                discoveryIssues.append(contentsOf: discovery.issues)
            } catch {
                writeError("error: \(error.localizedDescription)")
                return 66
            }
        }

        for issue in discoveryIssues.sorted(by: { $0.filePath < $1.filePath }) {
            writeError("\(issue.filePath): error: Could not inspect path: \(issue.message)")
        }

        let analyzer = SwiftSourceAnalyzer()
        var analyzedFiles: [String] = []
        var diagnostics: [Diagnostic] = []
        let discoveredFiles = discoveredFilesByPath.values.sorted { $0.path < $1.path }

        for file in discoveredFiles {
            do {
                let source = try String(contentsOf: file, encoding: .utf8)
                diagnostics.append(contentsOf: analyzer.analyze(
                    source: source,
                    filePath: file.path
                ))
                analyzedFiles.append(file.path)
            } catch {
                writeError("\(file.path): error: Could not read file: \(error.localizedDescription)")
            }
        }

        let analysisWasPrevented = analyzedFiles.isEmpty
            && (!discoveredFiles.isEmpty || !discoveryIssues.isEmpty)
        guard !analysisWasPrevented else {
            return 1
        }

        let result = AnalysisResult(
            inputPaths: options.inputPaths,
            analyzedFiles: analyzedFiles,
            diagnostics: diagnostics
        )

        do {
            let output = try options.format.reporter.render(result)
            try writeOutput(output, to: options.outputPath)
        } catch {
            writeError("error: Could not generate report: \(error.localizedDescription)")
            return 74
        }

        return 0
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
    }

    private static func writeOutput(_ output: String, to outputPath: String?) throws {
        if let outputPath {
            let text = output.isEmpty ? "" : "\(output)\n"
            let data = Data(text.utf8)
            try data.write(
                to: URL(fileURLWithPath: outputPath).standardizedFileURL,
                options: .atomic
            )
        } else if !output.isEmpty {
            FileHandle.standardOutput.write(Data("\(output)\n".utf8))
        }
    }
}

private struct CommandOptions {
    static let usage = """
        Usage: swift-accessibility-checker [--format xcode|json] [--output path] \
        <file-or-directory> [...]
        """

    let inputPaths: [String]
    let format: ReportFormat
    let outputPath: String?

    init(arguments: [String]) throws {
        var inputPaths: [String] = []
        var format = ReportFormat.xcode
        var outputPath: String?
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--format":
                index += 1
                guard index < arguments.count else {
                    throw CommandOptionsError.missingValue(argument)
                }
                format = try ReportFormat(argument: arguments[index])
            case let value where value.hasPrefix("--format="):
                format = try ReportFormat(argument: String(value.dropFirst("--format=".count)))
            case "--output":
                index += 1
                guard index < arguments.count else {
                    throw CommandOptionsError.missingValue(argument)
                }
                outputPath = arguments[index]
            case let value where value.hasPrefix("--output="):
                let path = String(value.dropFirst("--output=".count))
                guard !path.isEmpty else {
                    throw CommandOptionsError.missingValue("--output")
                }
                outputPath = path
            case let value where value.hasPrefix("-"):
                throw CommandOptionsError.unknownOption(argument)
            default:
                inputPaths.append(argument)
            }

            index += 1
        }

        guard !inputPaths.isEmpty else {
            throw CommandOptionsError.missingInput
        }

        self.inputPaths = inputPaths
        self.format = format
        self.outputPath = outputPath
    }
}

private enum ReportFormat: String {
    case xcode
    case json

    init(argument: String) throws {
        guard let format = Self(rawValue: argument.lowercased()) else {
            throw CommandOptionsError.invalidFormat(argument)
        }
        self = format
    }

    var reporter: any AnalysisReporter {
        switch self {
        case .xcode:
            XcodeReporter()
        case .json:
            JSONReporter()
        }
    }
}

private enum CommandOptionsError: LocalizedError {
    case missingInput
    case missingValue(String)
    case invalidFormat(String)
    case unknownOption(String)

    var errorDescription: String? {
        switch self {
        case .missingInput:
            return "No Swift file or directory was provided"
        case .missingValue(let option):
            return "Missing value for option: \(option)"
        case .invalidFormat(let format):
            return "Unsupported report format: \(format)"
        case .unknownOption(let option):
            return "Unknown option: \(option)"
        }
    }
}
