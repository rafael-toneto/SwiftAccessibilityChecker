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
            targetName: target.name
        )
    }
}

private func makeBuildCommands(
    executable: URL,
    swiftFiles: [URL],
    targetName: String
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
            arguments: sortedSwiftFiles.map(\.path),
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
            targetName: target.displayName
        )
    }
}
#endif
