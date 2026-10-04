import Foundation
import SwiftAccessibilityCheckerCore

/// Keeps human reports and machine diagnostics together, using one analysis result.
public struct ReportBundleWriter: Sendable {
    public static let fileNames = ["report.html", "report.md", "report.txt", "report.json", "warnings.txt"]

    public init() {}

    @discardableResult
    public func write(_ result: AnalysisResult, to directory: URL) throws -> URL {
        let directory = directory.standardizedFileURL
        let reporters: [any AnalysisReporter] = [
            HTMLReporter(), MarkdownReporter(), TextReporter(), JSONReporter(), XcodeReporter()
        ]
        // Render everything before replacing reports from a previous run.
        let outputs = try reporters.map { try $0.render(result) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in Self.fileNames {
            let url = directory.appendingPathComponent(name)
            // Never follow report-file symlinks into a project's source tree.
            if (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
                throw ReportBundleError.symbolicLink(url.path)
            }
        }
        for (name, output) in zip(Self.fileNames, outputs) {
            let url = directory.appendingPathComponent(name)
            let text = output.isEmpty ? "" : output + "\n"
            try Data(text.utf8).write(to: url, options: .atomic)
        }
        return directory.appendingPathComponent("report.html")
    }
}

public enum ReportBundleError: LocalizedError {
    case symbolicLink(String)

    public var errorDescription: String? {
        switch self {
        case .symbolicLink(let path): "O destino do relatório é um link simbólico: \(path)"
        }
    }
}
