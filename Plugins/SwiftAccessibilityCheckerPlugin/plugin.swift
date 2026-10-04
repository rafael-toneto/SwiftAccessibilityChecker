import Foundation
import PackagePlugin

@main
struct SwiftAccessibilityCheckerPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: any Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? any SourceModuleTarget else {
            return []
        }

        let swiftFiles = sourceTarget.sourceFiles(withSuffix: "swift").map(\.url)
        let executable = try context.tool(named: "swift-accessibility-checker").url

        return makeBuildCommands(
            executable: executable,
            swiftFiles: swiftFiles,
            targetName: target.name,
            workDirectory: context.pluginWorkDirectoryURL
        )
    }
}

private func makeBuildCommands(
    executable: URL,
    swiftFiles: [URL],
    targetName: String,
    workDirectory: URL
) -> [Command] {
    let sortedSwiftFiles = swiftFiles
        .filter { $0.pathExtension == "swift" }
        .sorted { $0.path < $1.path }

    guard !sortedSwiftFiles.isEmpty else {
        return []
    }

    return [
        .buildCommand(
            displayName: "Checking Swift accessibility in \(targetName)",
            executable: executable,
            arguments: [
                "--report-directory",
                workDirectory.appendingPathComponent("SwiftAccessibilityReport").path,
                "--"
            ] + sortedSwiftFiles.map(\.path),
            // Reports are private build artifacts, not generated app resources.
            // Declaring HTML/JSON in outputFiles can bundle source excerpts in the app.
            inputFiles: sortedSwiftFiles
        )
    ]
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftAccessibilityCheckerPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let swiftFiles = target.inputFiles
            .filter { $0.type == .source && $0.url.pathExtension == "swift" }
            .map(\.url)
        let executable = try context.tool(named: "swift-accessibility-checker").url

        return makeBuildCommands(
            executable: executable,
            swiftFiles: swiftFiles,
            targetName: target.displayName,
            workDirectory: context.pluginWorkDirectoryURL
        )
    }
}
#endif
