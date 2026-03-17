import SwiftUI

enum BrainRotTheme {
    // MARK: - Claude Brand Palette

    // Backgrounds
    static let background = Color(red: 0.957, green: 0.953, blue: 0.933)       // #F4F3EE warm cream
    static let cardBackground = Color.white                                       // #FFFFFF
    static let cardBorder = Color(red: 0.910, green: 0.898, blue: 0.863)        // #E8E5DC subtle border

    // Text
    static let textPrimary = Color(red: 0.239, green: 0.224, blue: 0.161)       // #3D3929 charcoal brown
    static let textSecondary = Color(red: 0.549, green: 0.522, blue: 0.467)     // #8C8577 warm gray

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
    static let goldColor = Color(red: 0.831, green: 0.659, blue: 0.263)
    static let silverColor = Color(red: 0.60, green: 0.58, blue: 0.55)
    static let bronzeColor = Color(red: 0.72, green: 0.49, blue: 0.30)

    // MARK: - Score Helpers

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 0..<30: return neonGreen
        case 30..<60: return neonBlue
        case 60..<80: return neonPurple
        default: return neonPink
        }
    }

    static func scoreLabel(for score: Int) -> String {
        switch score {
        case 0..<20: return "ECSTATIC"
        case 20..<40: return "HAPPY"
        case 40..<60: return "NEUTRAL"
        case 60..<80: return "SAD"
        case 80..<95: return "DISTRESSED"
        default: return "ZOMBIE"
        }
    }

    static func scoreEmoji(for score: Int) -> String {
        switch score {
        case 0..<20: return "\u{1F9D8}"
        case 20..<40: return "\u{1F33F}"
        case 40..<60: return "\u{1F4F1}"
        case 60..<80: return "\u{1F9DF}"
        default: return "\u{1F9E0}\u{1F480}"
        }
    }

    static func tierBadgeColor(for score: Int) -> Color {
        switch score {
        case 0..<30: return neonGreen
        case 30..<60: return neonBlue
        case 60..<80: return neonPurple
        default: return neonPink
        }
    }
}
