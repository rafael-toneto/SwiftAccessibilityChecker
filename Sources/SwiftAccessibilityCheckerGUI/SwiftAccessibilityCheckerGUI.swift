import AppKit
import Foundation
import SwiftUI
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerReporter

@main
struct SwiftAccessibilityCheckerGUIApp: App {
    @StateObject private var model = CheckerViewModel()

    var body: some Scene {
        WindowGroup("Swift Accessibility Checker") {
            CheckerView(model: model)
        }
    }
}

private struct CheckerView: View {
    @ObservedObject var model: CheckerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Swift Accessibility Checker")
                    .font(.title.bold())
                Text("Analise fontes SwiftUI e gere relatórios para revisão.")
                    .foregroundStyle(.secondary)
            }

            GroupBox("1. Código do app") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.sourcePath.isEmpty ? "Nenhuma pasta selecionada" : model.sourcePath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(model.sourcePath.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
                        Button("Escolher pasta de fontes…") { model.chooseSource() }
                        if !model.recentSources.isEmpty {
                            Menu("Recentes") {
                                ForEach(model.recentSources, id: \.self) { path in
                                    Button(path) { model.useRecentSource(path) }
                                }
                            }
                        }
                    }
                    Text("Escolha a pasta do app, como Maeuse, Capelo ou Sources. A análise percorre os arquivos .swift dessa pasta.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            GroupBox("2. Onde salvar os relatórios") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.reportsRootPath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Alterar pasta…") { model.chooseReportsRoot() }
                    Text("Cada execução cria uma pasta com data e hora. Os relatórios ficam fora do código analisado por padrão.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            HStack(spacing: 12) {
                Button("Gerar relatórios") { model.runAnalysis() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(model.sourcePath.isEmpty || model.isRunning)
                if model.isRunning {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analisando…")
                        .foregroundStyle(.secondary)
                }
            }

            if let lastRun = model.lastRun {
                GroupBox("Resultado") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lastRun.summary)
                            .font(.headline)
                        if lastRun.coverageIssueCount > 0 {
                            Text("A análise foi incompleta: \(lastRun.coverageIssueCount) \(lastRun.coverageIssueCount == 1 ? "problema" : "problemas") de leitura. Consulte o relatório.")
                                .foregroundStyle(.orange)
                        } else if lastRun.findingCount == 0 {
                            Text("Nenhum aviso nas regras verificadas. Valide a interface em execução.")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Button("Abrir relatório HTML") { model.openReport() }
                            Button("Mostrar arquivos no Finder") { model.showReportsInFinder() }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                }
            }

            Spacer(minLength: 0)
            Text("Os avisos indicam pontos para revisão; não confirmam barreiras na interface.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 650, minHeight: 490)
        .alert("Não foi possível concluir a análise", isPresented: $model.showsError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage)
        }
    }
}

@MainActor
private final class CheckerViewModel: ObservableObject {
    @Published private(set) var sourcePath: String
    @Published private(set) var recentSources: [String]
    @Published private(set) var reportsRootPath: String
    @Published private(set) var lastRun: GUIRunSummary?
    @Published private(set) var isRunning = false
    @Published var showsError = false
    @Published private(set) var errorMessage = ""

    private enum PreferenceKey {
        static let recentSources = "SwiftAccessibilityCheckerGUI.recentSources"
        static let reportsRoot = "SwiftAccessibilityCheckerGUI.reportsRoot"
    }

    init() {
        let defaults = UserDefaults.standard
        let recent = (defaults.stringArray(forKey: PreferenceKey.recentSources) ?? [])
            .filter { FileManager.default.fileExists(atPath: $0) }
        recentSources = recent
        sourcePath = recent.first ?? ""
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        reportsRootPath = defaults.string(forKey: PreferenceKey.reportsRoot)
            ?? documents.appendingPathComponent("SwiftAccessibilityChecker-Relatorios").path
    }

    func chooseSource() {
        let panel = NSOpenPanel()
        panel.message = "Escolha a pasta com os arquivos Swift do app"
        panel.prompt = "Usar esta pasta"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if !sourcePath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: sourcePath)
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        useRecentSource(url.standardizedFileURL.path)
    }

    func useRecentSource(_ path: String) {
        guard FileManager.default.fileExists(atPath: path) else {
            showError("A pasta não existe mais: \(path)")
            return
        }
        sourcePath = path
        lastRun = nil
        recentSources.removeAll { $0 == path }
        recentSources.insert(path, at: 0)
        recentSources = Array(recentSources.prefix(8))
        UserDefaults.standard.set(recentSources, forKey: PreferenceKey.recentSources)
    }

    func chooseReportsRoot() {
        let panel = NSOpenPanel()
        panel.message = "Escolha onde guardar as pastas dos relatórios"
        panel.prompt = "Salvar aqui"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        let current = URL(fileURLWithPath: reportsRootPath)
        panel.directoryURL = FileManager.default.fileExists(atPath: current.path)
            ? current : current.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        reportsRootPath = url.standardizedFileURL.path
        UserDefaults.standard.set(reportsRootPath, forKey: PreferenceKey.reportsRoot)
    }

    func runAnalysis() {
        guard !sourcePath.isEmpty, !isRunning else { return }
        let input = sourcePath
        let reportsRoot = reportsRootPath
        isRunning = true
        lastRun = nil

        Task {
            do {
                let summary = try await Task.detached(priority: .userInitiated) {
                    try GUIAnalysis.perform(inputPath: input, reportsRootPath: reportsRoot)
                }.value
                lastRun = summary
                isRunning = false
                openReport()
            } catch {
                isRunning = false
                showError(error.localizedDescription)
            }
        }
    }

    func openReport() {
        guard let lastRun else { return }
        if !NSWorkspace.shared.open(URL(fileURLWithPath: lastRun.reportPath)) {
            showError("O relatório foi salvo, mas não abriu no navegador: \(lastRun.reportPath)")
        }
    }

    func showReportsInFinder() {
        guard let lastRun else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: lastRun.reportPath)])
    }

    private func showError(_ message: String) {
        errorMessage = message
        showsError = true
    }
}

private struct GUIRunSummary: Sendable {
    let reportPath: String
    let fileCount: Int
    let findingCount: Int
    let coverageIssueCount: Int

    var summary: String {
        let files = fileCount == 1 ? "arquivo analisado" : "arquivos analisados"
        let findings = findingCount == 1 ? "aviso para revisar" : "avisos para revisar"
        return "\(fileCount) \(files) · \(findingCount) \(findings)"
    }
}

private enum GUIAnalysis {
    static func perform(inputPath: String, reportsRootPath: String) throws -> GUIRunSummary {
        let run = ProjectAnalysisRunner().run(inputPaths: [inputPath])
        let result = run.result
        guard run.invalidInputPaths.isEmpty else {
            throw GUIAnalysisError.invalidInput(result.analysisIssues?.first?.message ?? inputPath)
        }
        guard !result.analyzedFiles.isEmpty else {
            throw GUIAnalysisError.noSwiftFiles
        }

        let sourceURL = URL(fileURLWithPath: inputPath)
        let sourceName = sourceURL.lastPathComponent
        let projectName = ["Sources", "Shared"].contains(sourceName)
            ? sourceURL.deletingLastPathComponent().lastPathComponent : sourceName
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let folderName = "\(projectName)-\(dateFormatter.string(from: Date()))"
        let root = URL(fileURLWithPath: reportsRootPath).standardizedFileURL
        var directory = root.appendingPathComponent(folderName, isDirectory: true)
        var suffix = 2
        while FileManager.default.fileExists(atPath: directory.path) {
            directory = root.appendingPathComponent("\(folderName)-\(suffix)", isDirectory: true)
            suffix += 1
        }

        let report = try ReportBundleWriter().write(result, to: directory)
        return GUIRunSummary(
            reportPath: report.path,
            fileCount: result.analyzedFiles.count,
            findingCount: result.summary.totalIssues,
            coverageIssueCount: result.analysisIssues?.count ?? 0
        )
    }
}

private enum GUIAnalysisError: LocalizedError {
    case invalidInput(String)
    case noSwiftFiles

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message): "Não foi possível abrir a pasta: \(message)"
        case .noSwiftFiles: "Nenhum arquivo Swift foi analisado. Escolha a pasta com os fontes do app."
        }
    }
}
