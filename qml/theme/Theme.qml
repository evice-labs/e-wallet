import QtQuick

QtObject {
    id: theme

    // ── Surfaces & Backgrounds ────────────────────────────────
    readonly property color bgCanvas: "#050508"
    readonly property color bgSurface: "#0E1015"
    readonly property color bgSurfaceElevated: "#15171F"
    readonly property color bgSurfaceSubtle: "#1B1D26"
    readonly property color bgInsetTrough: "#121319"
    readonly property color bgGlassOverlay: Qt.rgba(0.02, 0.02, 0.03, 0.85)

    // ── Borders, Bevels & Lighting ────────────────────────────
    readonly property color borderSubtle: "#222530"
    readonly property color borderCard: "#2B2E3C"
    readonly property color borderActive: "#0A70F5"
    readonly property color bevelHighlightTop: Qt.rgba(1.0, 1.0, 1.0, 0.22)
    readonly property color bevelHighlightSubtle: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    readonly property color innerShadowDark: Qt.rgba(0.0, 0.0, 0.0, 0.65)
    readonly property color shadowDropDark: Qt.rgba(0.0, 0.0, 0.0, 0.50)

    // ── Primary Tactile Blue Button (Reference) ───────────────
    readonly property color btnPrimaryTop: "#0E76FA"
    readonly property color btnPrimaryBottom: "#0052CC"
    readonly property color btnPrimaryHoverTop: "#1E82FF"
    readonly property color btnPrimaryHoverBottom: "#0A5CD6"
    readonly property color btnPrimaryPressed: "#0040A3"
    readonly property color btnPrimaryBorderTop: Qt.rgba(1.0, 1.0, 1.0, 0.40)
    readonly property color btnPrimaryBorderSides: "#0B60DE"
    readonly property color btnPrimaryShadow: Qt.rgba(0.04, 0.44, 0.96, 0.35)

    // ── Secondary Tactile Charcoal Button (Reference) ─────────
    readonly property color btnSecondaryTop: "#1F212B"
    readonly property color btnSecondaryBottom: "#15171F"
    readonly property color btnSecondaryHoverTop: "#282A36"
    readonly property color btnSecondaryHoverBottom: "#1B1D26"
    readonly property color btnSecondaryPressed: "#0E1015"
    readonly property color btnSecondaryBorderTop: Qt.rgba(1.0, 1.0, 1.0, 0.18)
    readonly property color btnSecondaryBorderSides: "#2A2D3A"
    readonly property color btnSecondaryShadow: Qt.rgba(0.0, 0.0, 0.0, 0.45)

    // ── Accent & Semantic Status Colors (Zero Icon) ───────────
    readonly property color accentOrange: "#FF8438"
    readonly property color statusSuccess: "#00E575"
    readonly property color statusWarning: "#EAB308"
    readonly property color statusDanger: "#EF4444"
    readonly property color statusShielded: "#A855F7"
    readonly property color statusPublic: "#0A70F5"

    // ── Typography ────────────────────────────────────────────
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#8E92A0"
    readonly property color textMuted: "#5F6372"
    readonly property color textDisabled: "#3D404D"

    readonly property string fontFamily: "Inter, -apple-system, Roboto, sans-serif"
    readonly property string fontMono: "JetBrains Mono, SF Mono, Menlo, monospace"

    readonly property int fontSizeHero: 28
    readonly property int fontSizeTitle: 20
    readonly property int fontSizeBody: 14
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeTiny: 10

    // ── Metrics & Geometry ────────────────────────────────────
    readonly property int radiusPill: 10
    readonly property int radiusButton: 8
    readonly property int radiusCard: 14
    readonly property int radiusInset: 8
    readonly property int radiusProgress: 5
}
