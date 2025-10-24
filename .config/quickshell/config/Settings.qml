import QtQuick
pragma Singleton

/**
 * Settings - Centralized configuration for the entire shell
 * All hardcoded values should be defined here for easy customization
 */
QtObject {
    // Path to background image if using image mode

    id: root

    // ========================================
    // Notification Settings
    // ========================================
    readonly property int notificationTimeout: 5000
    readonly property int notificationMaxStack: 4
    readonly property int notificationWidth: 380
    readonly property int notificationHeight: 100
    readonly property int notificationTopMargin: 50
    readonly property int notificationRightMargin: 16
    readonly property int notificationSpacing: 105
    readonly property int notificationDismissThreshold: 100
    // ========================================
    // OSD Settings
    // ========================================
    readonly property int osdTimeout: 1000
    readonly property int osdWidth: 360
    readonly property int osdHeight: 70
    readonly property int osdBottomMargin: 10
    // ========================================
    // Bar Settings
    // ========================================
    readonly property int barHeight: 30
    readonly property int barExclusiveZone: 35
    readonly property int barPillHeight: 24
    readonly property int barPillRadius: 12
    readonly property int barPillPadding: 16
    readonly property int barContentMargin: 12
    readonly property int barModuleSpacing: 6
    readonly property int barWorkspaceSpacing: 8
    // Workspace indicator
    readonly property int workspaceIndicatorHeight: 12
    readonly property int workspaceIndicatorInactiveWidth: 12
    readonly property int workspaceIndicatorActiveWidth: 24
    // ========================================
    // Animation Settings
    // ========================================
    readonly property int animationDurationShort: 150
    readonly property int animationDurationMedium: 250
    readonly property int animationDurationLong: 400
    // Easing curves
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingEmphasized: Easing.BezierSpline
    readonly property int easingDecelerate: Easing.OutCubic
    readonly property int easingAccelerate: Easing.InCubic
    // ========================================
    // Layout Settings
    // ========================================
    readonly property int cardRadius: 12
    readonly property int cardBorderWidth: 1
    readonly property int cardMargin: 4
    readonly property int cardPadding: 12
    // ========================================
    // Typography Settings
    // ========================================
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 12
    readonly property int fontSizeLarge: 12
    readonly property int fontSizeIcon: 24
    readonly property string fontFamilyDefault: "sans-serif"
    readonly property string fontFamilyIcons: "Material Symbols"
    // ========================================
    // Flickable Settings
    // ========================================
    readonly property int flickMaxVelocity: 2500
    readonly property int flickDeceleration: 1500
    readonly property int flickSlideDistance: 400
    // ========================================
    // Background Settings
    // ========================================
    readonly property string backgroundType: "image"
    readonly property string backgroundColor: "#091518"
    readonly property string backgroundImagePath: "/home/httpkiwi/Pictures/cozycabininthewoods.webp"
}
