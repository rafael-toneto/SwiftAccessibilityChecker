import SwiftAccessibilityCheckerCore

public enum AccessibilityRuleDefinitions {
    public static let missingLabel = AccessibilityRuleDefinition(
        identifier: "SAC001",
        title: "Missing accessibility label",
        description: "Button with image-only or empty content should provide an accessibility label",
        severity: .high,
        rationale: "An unlabeled control can prevent VoiceOver users from understanding its purpose.",
        suggestion: "Add an accessibilityLabel that describes the action, or use a control initializer with a meaningful visible title.",
        references: [
            apple("accessibilityLabel", "https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)"),
            wcag("1.1.1 Non-text Content", "non-text-content"),
            wcag("4.1.2 Name, Role, Value", "name-role-value")
        ]
    )

    public static let imageAccessibility = AccessibilityRuleDefinition(
        identifier: "SAC002",
        title: "Image accessibility treatment",
        description: "Image should be labeled or explicitly hidden from accessibility",
        severity: .medium,
        rationale: "An image needs a clear semantic intent so assistive technologies either describe it or ignore it as decoration.",
        suggestion: "Provide a meaningful accessibilityLabel, use accessibilityRepresentation, or mark a decorative image with accessibilityHidden(true).",
        references: [
            apple("VoiceOver", "https://developer.apple.com/design/human-interface-guidelines/voiceover"),
            wcag("1.1.1 Non-text Content", "non-text-content")
        ]
    )

    public static let fixedFontSize = AccessibilityRuleDefinition(
        identifier: "SAC003",
        title: "Fixed font size",
        description: "Fixed font size may not support Dynamic Type",
        severity: .medium,
        rationale: "A fixed system font size can make text harder to read when the user requests larger accessibility sizes.",
        suggestion: "Prefer a semantic text style such as .body or scale custom typography with UIFontMetrics.",
        references: [
            apple("Typography", "https://developer.apple.com/design/human-interface-guidelines/typography"),
            wcag("1.4.4 Resize Text", "resize-text")
        ]
    )

    public static let smallTouchTarget = AccessibilityRuleDefinition(
        identifier: "SAC004",
        title: "Potentially small touch target",
        description: "Explicit frame may create a touch target smaller than 44 x 44 points",
        severity: .medium,
        rationale: "Small interactive regions can be difficult to activate for people with limited motor precision.",
        suggestion: "Increase the effective hit area to at least 44 x 44 points or confirm that padding and layout provide an equivalent target.",
        references: [
            apple("Accessibility", "https://developer.apple.com/design/human-interface-guidelines/accessibility"),
            wcag("2.5.5 Target Size (Enhanced)", "target-size-enhanced"),
            wcag("2.5.8 Target Size (Minimum)", "target-size-minimum")
        ]
    )

    public static let colorOnlyInformation = AccessibilityRuleDefinition(
        identifier: "SAC005",
        title: "Information conveyed by color",
        description: "State-dependent color may need a text, shape, or icon alternative",
        severity: .low,
        rationale: "Color alone may not communicate state to users with color-vision or other visual impairments.",
        suggestion: "Add a state-dependent text, symbol, shape, or accessibility value in addition to the color change.",
        references: [
            apple("Color", "https://developer.apple.com/design/human-interface-guidelines/color"),
            wcag("1.4.1 Use of Color", "use-of-color")
        ]
    )

    public static let emptyAccessibilityMetadata = AccessibilityRuleDefinition(
        identifier: "SAC006",
        title: "Empty accessibility metadata",
        description: "Accessibility metadata must not be empty",
        severity: .high,
        rationale: "Empty metadata can replace useful default semantics with no information for assistive technologies.",
        suggestion: "Provide meaningful content or remove the empty modifier so the framework can preserve its default semantics.",
        references: [
            apple("View accessibility", "https://developer.apple.com/documentation/swiftui/view-accessibility"),
            wcag("4.1.2 Name, Role, Value", "name-role-value")
        ]
    )

    public static let hiddenInteractiveControl = AccessibilityRuleDefinition(
        identifier: "SAC007",
        title: "Interactive control hidden from accessibility",
        description: "Interactive control is hidden from accessibility features",
        severity: .high,
        rationale: "A control hidden from the accessibility tree may be unavailable to people using VoiceOver or other assistive features.",
        suggestion: "Remove accessibilityHidden(true) from the control or expose an accessible equivalent action.",
        references: [
            apple("accessibilityHidden", "https://developer.apple.com/documentation/swiftui/view/accessibilityhidden(_:)"),
            wcag("4.1.2 Name, Role, Value", "name-role-value")
        ]
    )

    public static let gestureOnlyInteraction = AccessibilityRuleDefinition(
        identifier: "SAC008",
        title: "Gesture-only interaction",
        description: "Gesture-only interaction may need an accessible control role or action",
        severity: .high,
        rationale: "A custom gesture without an accessible equivalent can make the action unavailable to assistive technology users.",
        suggestion: "Prefer a standard control or provide an accessibility action, representation, or appropriate interactive trait.",
        references: [
            apple("Accessible controls", "https://developer.apple.com/documentation/swiftui/accessible-controls"),
            wcag("2.1.1 Keyboard", "keyboard"),
            wcag("4.1.2 Name, Role, Value", "name-role-value")
        ]
    )

    public static let restrictedDynamicType = AccessibilityRuleDefinition(
        identifier: "SAC009",
        title: "Restricted Dynamic Type",
        description: "A fixed or capped Dynamic Type size may limit accessible text scaling",
        severity: .medium,
        rationale: "Restricting Dynamic Type can prevent users from reaching the larger text sizes they need.",
        suggestion: "Remove the restriction or ensure the supported range reaches the largest accessibility category.",
        references: [
            apple("dynamicTypeSize", "https://developer.apple.com/documentation/swiftui/view/dynamictypesize(_:)"),
            apple("Typography", "https://developer.apple.com/design/human-interface-guidelines/typography"),
            wcag("1.4.4 Resize Text", "resize-text")
        ]
    )

    private static func apple(_ criterion: String, _ url: String) -> StandardReference {
        StandardReference(source: "Apple", criterion: criterion, url: url)
    }

    private static func wcag(_ criterion: String, _ fragment: String) -> StandardReference {
        StandardReference(
            source: "WCAG 2.2",
            criterion: criterion,
            url: "https://www.w3.org/TR/WCAG22/#\(fragment)"
        )
    }
}
