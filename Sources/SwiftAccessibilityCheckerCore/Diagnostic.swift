public enum DiagnosticSeverity: String, Codable, CaseIterable, Equatable, Sendable {
    case low
    case medium
    case high
}

public struct StandardReference: Codable, Equatable, Sendable {
    public let source: String
    public let criterion: String
    public let url: String

    public init(source: String, criterion: String, url: String) {
        self.source = source
        self.criterion = criterion
        self.url = url
    }
}

public struct AccessibilityRuleDefinition: Equatable, Sendable {
    public let identifier: String
    public let title: String
    public let description: String
    public let severity: DiagnosticSeverity
    public let rationale: String
    public let suggestion: String
    public let references: [StandardReference]

    public init(
        identifier: String,
        title: String,
        description: String,
        severity: DiagnosticSeverity,
        rationale: String,
        suggestion: String,
        references: [StandardReference]
    ) {
        self.identifier = identifier
        self.title = title
        self.description = description
        self.severity = severity
        self.rationale = rationale
        self.suggestion = suggestion
        self.references = references
    }
}

public struct Diagnostic: Codable, Equatable, Sendable {
    public let ruleIdentifier: String
    public let title: String
    public let description: String
    public let severity: DiagnosticSeverity
    public let filePath: String
    public let line: Int
    public let column: Int
    public let sourceExcerpt: String?
    public let rationale: String
    public let suggestion: String
    public let references: [StandardReference]

    /// Backward-compatible concise text used by earlier clients.
    public var message: String { description }

    public init(
        rule: AccessibilityRuleDefinition,
        description: String? = nil,
        filePath: String,
        line: Int,
        column: Int,
        sourceExcerpt: String? = nil
    ) {
        self.ruleIdentifier = rule.identifier
        self.title = rule.title
        self.description = description ?? rule.description
        self.severity = rule.severity
        self.filePath = filePath
        self.line = line
        self.column = column
        self.sourceExcerpt = sourceExcerpt
        self.rationale = rule.rationale
        self.suggestion = rule.suggestion
        self.references = rule.references
    }

    private init(
        ruleIdentifier: String,
        title: String,
        description: String,
        severity: DiagnosticSeverity,
        filePath: String,
        line: Int,
        column: Int,
        sourceExcerpt: String?,
        rationale: String,
        suggestion: String,
        references: [StandardReference]
    ) {
        self.ruleIdentifier = ruleIdentifier
        self.title = title
        self.description = description
        self.severity = severity
        self.filePath = filePath
        self.line = line
        self.column = column
        self.sourceExcerpt = sourceExcerpt
        self.rationale = rationale
        self.suggestion = suggestion
        self.references = references
    }

    public func addingSourceExcerpt(_ sourceExcerpt: String?) -> Diagnostic {
        Diagnostic(
            ruleIdentifier: ruleIdentifier,
            title: title,
            description: description,
            severity: severity,
            filePath: filePath,
            line: line,
            column: column,
            sourceExcerpt: sourceExcerpt,
            rationale: rationale,
            suggestion: suggestion,
            references: references
        )
    }
}
