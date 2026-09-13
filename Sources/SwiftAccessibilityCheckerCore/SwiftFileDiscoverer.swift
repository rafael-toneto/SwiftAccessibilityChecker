import Foundation

public struct FileDiscoveryIssue: Equatable, Sendable {
    public let filePath: String
    public let message: String

    public init(filePath: String, message: String) {
        self.filePath = filePath
        self.message = message
    }
}

public struct SwiftFileDiscoveryResult: Equatable, Sendable {
    public let files: [URL]
    public let issues: [FileDiscoveryIssue]

    public init(files: [URL], issues: [FileDiscoveryIssue]) {
        self.files = files
        self.issues = issues
    }
}

public enum SwiftFileDiscoveryError: LocalizedError, Equatable {
    case pathDoesNotExist(String)
    case inputIsNotSwiftFile(String)
    case unsupportedInput(String)

    public var errorDescription: String? {
        switch self {
        case .pathDoesNotExist(let path):
            return "Path does not exist: \(path)"
        case .inputIsNotSwiftFile(let path):
            return "Input file must have a .swift extension: \(path)"
        case .unsupportedInput(let path):
            return "Input path is neither a regular file nor a directory: \(path)"
        }
    }
}

public struct SwiftFileDiscoverer {
    public static let ignoredDirectoryNames: Set<String> = [
        ".git",
        ".build",
        "DerivedData",
        "Pods",
        "Carthage",
        "SourcePackages"
    ]

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func discover(at inputPath: String) throws -> SwiftFileDiscoveryResult {
        let inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: inputURL.path, isDirectory: &isDirectory) else {
            throw SwiftFileDiscoveryError.pathDoesNotExist(inputPath)
        }

        if !isDirectory.boolValue {
            guard inputURL.pathExtension == "swift" else {
                throw SwiftFileDiscoveryError.inputIsNotSwiftFile(inputPath)
            }

            return SwiftFileDiscoveryResult(files: [inputURL], issues: [])
        }

        var files: [URL] = []
        var issues: [FileDiscoveryIssue] = []
        collectSwiftFiles(in: inputURL, files: &files, issues: &issues)

        return SwiftFileDiscoveryResult(
            files: files.sorted { $0.path < $1.path },
            issues: issues.sorted { $0.filePath < $1.filePath }
        )
    }

    private func collectSwiftFiles(
        in directory: URL,
        files: inout [URL],
        issues: inout [FileDiscoveryIssue]
    ) {
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey
        ]

        let children: [URL]
        do {
            children = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: Array(resourceKeys),
                options: []
            )
        } catch {
            issues.append(
                FileDiscoveryIssue(
                    filePath: directory.path,
                    message: error.localizedDescription
                )
            )
            return
        }

        for child in children.sorted(by: { $0.path < $1.path }) {
            let values: URLResourceValues
            do {
                values = try child.resourceValues(forKeys: resourceKeys)
            } catch {
                issues.append(
                    FileDiscoveryIssue(
                        filePath: child.path,
                        message: error.localizedDescription
                    )
                )
                continue
            }

            if values.isDirectory == true {
                guard !Self.ignoredDirectoryNames.contains(child.lastPathComponent) else {
                    continue
                }

                // Directory symlinks are skipped to avoid cycles and duplicate analysis.
                guard values.isSymbolicLink != true else {
                    continue
                }

                collectSwiftFiles(in: child, files: &files, issues: &issues)
            } else if child.pathExtension == "swift" {
                files.append(child)
            }
        }
    }
}
