import Foundation
import SwiftAccessibilityCheckerAnalyzer
import SwiftAccessibilityCheckerCore
import SwiftAccessibilityCheckerReporter
import Testing

@Suite("Structured reporting")
struct ReporterTests {
    @Test("Builds a deterministic summary and diagnostic order")
    func buildsDeterministicSummaryAndOrder() {
        let result = AnalysisResult(
            generatedAt: Date(timeIntervalSince1970: 0),
            inputPaths: ["Sources"],
            analyzedFiles: ["B.swift", "A.swift"],
            diagnostics: [
                diagnostic(
                    rule: AccessibilityRuleDefinitions.fixedFontSize,
                    filePath: "B.swift",
                    line: 8
                ),
                diagnostic(
                    rule: AccessibilityRuleDefinitions.missingLabel,
                    filePath: "A.swift",
                    line: 4
                )
            ]
        )

        #expect(result.analyzedFiles == ["A.swift", "B.swift"])
        #expect(result.diagnostics.map(\.ruleIdentifier) == ["SAC001", "SAC003"])
        #expect(result.summary.totalIssues == 2)
        #expect(result.summary.bySeverity == ["high": 1, "medium": 1, "low": 0])
        #expect(result.summary.byRule == ["SAC001": 1, "SAC003": 1])
    }

    @Test("Renders a stable JSON snapshot")
    func rendersStableJSONSnapshot() throws {
        let result = AnalysisResult(
            generatedAt: Date(timeIntervalSince1970: 0),
            inputPaths: ["ProfileView.swift"],
            analyzedFiles: ["/tmp/ProfileView.swift"],
            diagnostics: [
                diagnostic(
                    rule: AccessibilityRuleDefinitions.fixedFontSize,
                    filePath: "/tmp/ProfileView.swift",
                    line: 18,
                    sourceExcerpt: ".font(.system(size: 16))"
                )
            ]
        )

        let output = try JSONReporter().render(result)

        #expect(output == #"""
        {
          "analyzedFiles" : [
            "/tmp/ProfileView.swift"
          ],
          "diagnostics" : [
            {
              "column" : 9,
              "description" : "Fixed font size may not support Dynamic Type",
              "filePath" : "/tmp/ProfileView.swift",
              "line" : 18,
              "rationale" : "A fixed system font size can make text harder to read when the user requests larger accessibility sizes.",
              "references" : [
                {
                  "criterion" : "Typography",
                  "source" : "Apple",
                  "url" : "https://developer.apple.com/design/human-interface-guidelines/typography"
                },
                {
                  "criterion" : "1.4.4 Resize Text",
                  "source" : "WCAG 2.2",
                  "url" : "https://www.w3.org/TR/WCAG22/#resize-text"
                }
              ],
              "ruleIdentifier" : "SAC003",
              "severity" : "medium",
              "sourceExcerpt" : ".font(.system(size: 16))",
              "suggestion" : "Prefer a semantic text style such as .body or scale custom typography with UIFontMetrics.",
              "title" : "Fixed font size"
            }
          ],
          "generatedAt" : "1970-01-01T00:00:00Z",
          "inputPaths" : [
            "ProfileView.swift"
          ],
          "schemaVersion" : "1.1",
          "summary" : {
            "byRule" : {
              "SAC003" : 1
            },
            "bySeverity" : {
              "high" : 0,
              "low" : 0,
              "medium" : 1
            },
            "totalIssues" : 1
          },
          "tool" : "Swift Accessibility Checker"
        }
        """#)
    }

    @Test("Keeps Xcode output concise and non-blocking")
    func rendersXcodeWarning() throws {
        let result = AnalysisResult(
            generatedAt: Date(timeIntervalSince1970: 0),
            inputPaths: ["ProfileView.swift"],
            analyzedFiles: ["ProfileView.swift"],
            diagnostics: [
                diagnostic(
                    rule: AccessibilityRuleDefinitions.fixedFontSize,
                    filePath: "ProfileView.swift",
                    line: 18
                )
            ]
        )

        #expect(
            XcodeReporter().render(result)
                == "ProfileView.swift:18:9: warning: "
                + "Fixed font size may not support Dynamic Type [SAC003] [medium]"
        )
    }

    private func diagnostic(
        rule: AccessibilityRuleDefinition,
        filePath: String,
        line: Int,
        sourceExcerpt: String? = nil
    ) -> Diagnostic {
        Diagnostic(
            rule: rule,
            filePath: filePath,
            line: line,
            column: 9,
            sourceExcerpt: sourceExcerpt
        )
    }
}
