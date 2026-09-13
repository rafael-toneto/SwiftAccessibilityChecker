public enum AccessibilityRuleCatalog {
    public static var defaultRules: [any AccessibilityRule] {
        [
            MissingLabelRule(),
            ImageAccessibilityRule(),
            FixedFontSizeRule(),
            SmallTouchTargetRule(),
            ColorOnlyInformationRule(),
            EmptyAccessibilityMetadataRule(),
            HiddenInteractiveControlRule(),
            GestureOnlyInteractionRule(),
            RestrictedDynamicTypeRule()
        ]
    }
}
