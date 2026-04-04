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

    // MARK: - Score Helpers

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 0..<30: return neonGreen
        case 30..<60: return neonBlue
        case 60..<85: return neonPurple
        default: return neonPink
        }
    }

    static func scoreLabel(for score: Int) -> String {
        switch score {
        case 0..<30: return "DIGITAL MONK"
        case 30..<60: return "GRASS TOUCHER"
        case 60..<85: return "DOOMSCROLLER"
        default: return "BRAINROT"
        }
    }

    static func scoreEmoji(for score: Int) -> String {
        switch score {
        case 0..<30: return "\u{2728}"
        case 30..<60: return "\u{1F33F}"
        case 60..<85: return "\u{1F4F1}"
        default: return "\u{1F480}"
        }
    }

    static func tierBadgeColor(for score: Int) -> Color {
        switch score {
        case 0..<30: return neonGreen
        case 30..<60: return neonBlue
        case 60..<85: return neonPurple
        default: return neonPink
        }
    }
}
