import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
#endif

struct SettingsView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Tier Breakdown
                        tierBreakdownCard

                        // About
                        aboutCard
                    }
                    .padding()
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Tier Breakdown

    private var tierBreakdownCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("Kraken Tiers")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            Text("Your daily screen time determines your kraken's mood:")
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)

            VStack(spacing: 8) {
                tierRow(name: "Digital Monk", range: "0 - 2h", color: Color(red: 0.55, green: 0.88, blue: 0.70))
                tierRow(name: "Grass Toucher", range: "2h - 4h", color: Color(red: 0.52, green: 0.82, blue: 0.78))
                tierRow(name: "Doomscroller", range: "4h - 6h", color: Color(red: 0.75, green: 0.62, blue: 0.88))
                tierRow(name: "Brainrot", range: "6h+", color: Color(red: 0.68, green: 0.65, blue: 0.63))
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tierRow(name: String, range: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .init(x: 0.4, y: 0.35),
                        startRadius: 2, endRadius: 14
                    )
                )
                .frame(width: 28, height: 28)

            Text(name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)

            Spacer()

            Text(range)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(BrainRotTheme.neonGreen)
                Text("About ScreenRot")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ScreenRot tracks your daily screen time and visualizes it through a kraken mascot that reacts to your usage.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Text("Use the Shield tab to set usage limits and block routines for specific apps. The Overview tab shows your daily breakdown, and Brain Health tracks your weekly trends.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
