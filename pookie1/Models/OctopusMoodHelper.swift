import SwiftUI

/// Lightweight mood helper for the main app target (mirrors OctopusMood from extension)
enum OctopusMood {
    case ecstatic, happy, neutral, sad, distressed, zombie

    static func from(score: Int) -> OctopusMood {
        switch score {
        case 0..<20:  return .ecstatic
        case 20..<40: return .happy
        case 40..<60: return .neutral
        case 60..<80: return .sad
        case 80..<95: return .distressed
        default:      return .zombie
        }
    }

    var bodyColor: Color {
        switch self {
        case .ecstatic:   return Color(red: 0.55, green: 0.88, blue: 0.70)
        case .happy:      return Color(red: 0.52, green: 0.82, blue: 0.78)
        case .neutral:    return Color(red: 0.60, green: 0.74, blue: 0.90)
        case .sad:        return Color(red: 0.75, green: 0.62, blue: 0.88)
        case .distressed: return Color(red: 0.92, green: 0.58, blue: 0.58)
        case .zombie:     return Color(red: 0.68, green: 0.65, blue: 0.63)
        }
    }

    var bodyColorDark: Color {
        switch self {
        case .ecstatic:   return Color(red: 0.40, green: 0.75, blue: 0.55)
        case .happy:      return Color(red: 0.38, green: 0.70, blue: 0.65)
        case .neutral:    return Color(red: 0.48, green: 0.62, blue: 0.78)
        case .sad:        return Color(red: 0.62, green: 0.48, blue: 0.75)
        case .distressed: return Color(red: 0.80, green: 0.45, blue: 0.45)
        case .zombie:     return Color(red: 0.52, green: 0.50, blue: 0.48)
        }
    }
}
