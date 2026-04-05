import SwiftUI

// MARK: - Color Light/Dark Helper

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Shared Theme (reads user preference from app group)

enum SharedTheme {
    static var colorScheme: ColorScheme? {
        let theme = UserDefaults(suiteName: "group.pookie1.shared")?.string(forKey: "appTheme") ?? "system"
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

enum BrainRotTheme {
    // MARK: - Claude Brand Palette

    // Backgrounds
    static let background = Color(
        light: Color(red: 0.957, green: 0.953, blue: 0.933),
        dark: Color(red: 0.11, green: 0.11, blue: 0.12)
    )
    static let cardBackground = Color(
        light: .white,
        dark: Color(red: 0.17, green: 0.17, blue: 0.18)
    )
    static let cardBorder = Color(
        light: Color(red: 0.910, green: 0.898, blue: 0.863),
        dark: Color(red: 0.25, green: 0.25, blue: 0.27)
    )

    // Text
    static let textPrimary = Color(
        light: Color(red: 0.239, green: 0.224, blue: 0.161),
        dark: Color(red: 0.93, green: 0.93, blue: 0.91)
    )
    static let textSecondary = Color(
        light: Color(red: 0.549, green: 0.522, blue: 0.467),
        dark: Color(red: 0.62, green: 0.60, blue: 0.56)
    )

    // Accent colors (softer tones for light background)
    static let neonPink = Color(red: 0.855, green: 0.467, blue: 0.337)          // #DA7756 Claude orange (primary)
    static let neonGreen = Color(red: 0.357, green: 0.663, blue: 0.482)         // #5BA97B soft green
    static let neonPurple = Color(red: 0.608, green: 0.420, blue: 0.769)        // #9B6BC4 soft purple
    static let neonBlue = Color(red: 0.357, green: 0.561, blue: 0.788)          // #5B8FC9 soft blue
    static let neonOrange = Color(red: 0.910, green: 0.569, blue: 0.353)        // #E8915A soft orange
    static let neonYellow = Color(red: 0.831, green: 0.659, blue: 0.263)        // #D4A843 soft gold

    // Gradients
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.855, green: 0.467, blue: 0.337),  // Claude orange
            Color(red: 0.757, green: 0.373, blue: 0.235)   // Warm rust
        ],
        startPoint: .leading, endPoint: .trailing
    )

    static let brainDamageGradient = LinearGradient(
        colors: [neonGreen, neonBlue, neonPurple, neonPink],
        startPoint: .leading, endPoint: .trailing
    )

    static let goldGradient = LinearGradient(
        colors: [neonYellow, neonOrange],
        startPoint: .top, endPoint: .bottom
    )

    // Rank colors for leaderboard
    static let goldColor = Color(red: 0.831, green: 0.659, blue: 0.263)         // #D4A843
    static let silverColor = Color(red: 0.60, green: 0.58, blue: 0.55)          // Warm silver
    static let bronzeColor = Color(red: 0.72, green: 0.49, blue: 0.30)          // Warm bronze

    // MARK: - Category Icon Colors (no red/yellow/green — those are tier colors)

    // Distinct palette — each hue clearly different from the others
    static let catRosePink   = Color(red: 0.80, green: 0.38, blue: 0.55)   // #CC6190  warm rose
    static let catViolet     = Color(red: 0.60, green: 0.35, blue: 0.75)   // #9959BF  rich violet
    static let catIndigo     = Color(red: 0.38, green: 0.35, blue: 0.80)   // #6159CC  deep indigo
    static let catCobalt     = Color(red: 0.28, green: 0.50, blue: 0.82)   // #4780D1  cobalt blue
    static let catTeal       = Color(red: 0.25, green: 0.60, blue: 0.65)   // #4099A6  ocean teal
    static let catCyan       = Color(red: 0.30, green: 0.65, blue: 0.72)   // #4DA6B8  bright cyan
    static let catSlateBlue  = Color(red: 0.42, green: 0.45, blue: 0.65)   // #6B73A6  slate blue
    static let catOrchid     = Color(red: 0.72, green: 0.42, blue: 0.68)   // #B86BAD  orchid
    static let catPlum       = Color(red: 0.55, green: 0.30, blue: 0.55)   // #8C4D8C  deep plum
    static let catSky        = Color(red: 0.35, green: 0.58, blue: 0.78)   // #5994C7  sky blue
    static let catNavy       = Color(red: 0.25, green: 0.32, blue: 0.58)   // #405294  navy
    static let catFuchsia    = Color(red: 0.75, green: 0.30, blue: 0.65)   // #BF4DA6  fuchsia
    static let catSteel      = Color(red: 0.45, green: 0.52, blue: 0.60)   // #738599  steel
    static let catLavender   = Color(red: 0.58, green: 0.48, blue: 0.72)   // #947AB8  lavender

    /// Stable color per category name — each category gets its own distinct hue
    static func categoryColor(for name: String) -> Color {
        let lower = name.lowercased()
        if lower.contains("social")                                    { return catRosePink }
        if lower.contains("entertainment") || lower.contains("video")  { return catViolet }
        if lower.contains("game")                                      { return catIndigo }
        if lower.contains("productivity")                              { return catCobalt }
        if lower.contains("education")                                 { return catTeal }
        if lower.contains("health") || lower.contains("fitness")       { return catCyan }
        if lower.contains("shopping")                                  { return catOrchid }
        if lower.contains("news") || lower.contains("reading")         { return catSlateBlue }
        if lower.contains("photo") || lower.contains("creative")       { return catLavender }
        if lower.contains("music")                                     { return catFuchsia }
        if lower.contains("travel") || lower.contains("navigation")    { return catSky }
        if lower.contains("finance") || lower.contains("business")     { return catNavy }
        if lower.contains("utility") || lower.contains("utilities")    { return catSteel }
        if lower.contains("communication") || lower.contains("message") { return catPlum }
        // Fallback: hash the name to pick a stable color
        let colors = [catRosePink, catViolet, catIndigo, catCobalt, catTeal, catCyan,
                      catSlateBlue, catOrchid, catPlum, catSky, catNavy, catFuchsia, catSteel, catLavender]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    // MARK: - Score Helpers

    static let doomRed = Color(red: 0.85, green: 0.25, blue: 0.25)

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 0..<30: return neonGreen
        case 30..<60: return neonOrange
        case 60..<85: return doomRed
        default: return neonPink
        }
    }

    static func scoreLabel(for score: Int) -> String {
        switch score {
        case 0..<30: return "ZEN MASTER"
        case 30..<60: return "CASUAL SCROLLER"
        case 60..<85: return "DOOMSCROLLER"
        default: return "BRAINROT"
        }
    }

    static func scoreEmoji(for score: Int) -> String {
        switch score {
        case 0..<30: return "\u{1F9D8}"
        case 30..<60: return "\u{1F4F1}"
        case 60..<85: return "\u{1F4F1}"
        default: return "\u{1F480}"
        }
    }

    static func tierBadgeColor(for score: Int) -> Color {
        switch score {
        case 0..<30: return neonGreen
        case 30..<60: return neonOrange
        case 60..<85: return doomRed
        default: return neonPink
        }
    }
}
