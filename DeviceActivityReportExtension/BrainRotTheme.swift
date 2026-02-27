import SwiftUI

enum BrainRotTheme {
    // Core palette
    static let background = Color(red: 0.05, green: 0.02, blue: 0.12)
    static let cardBackground = Color(red: 0.10, green: 0.06, blue: 0.18)
    static let neonPink = Color(red: 1.0, green: 0.18, blue: 0.53)
    static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.65)
    static let neonPurple = Color(red: 0.69, green: 0.24, blue: 1.0)
    static let neonBlue = Color(red: 0.25, green: 0.58, blue: 1.0)
    static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let neonYellow = Color(red: 1.0, green: 0.9, blue: 0.2)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)

    // Gradients
    static let accentGradient = LinearGradient(
        colors: [neonPink, neonPurple],
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
    static let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let silverColor = Color(red: 0.75, green: 0.75, blue: 0.8)
    static let bronzeColor = Color(red: 0.8, green: 0.5, blue: 0.2)

    // Score helpers
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
        case 0..<20: return "DIGITAL MONK"
        case 20..<40: return "GRASS TOUCHER"
        case 40..<60: return "CASUAL SCROLLER"
        case 60..<80: return "DOOMSCROLLER"
        case 80..<95: return "BRAINROT MODE"
        default: return "FULL BRAINROT"
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
