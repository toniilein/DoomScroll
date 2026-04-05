import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
#endif

struct SettingsView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @Environment(\.scrollToTopTrigger) private var scrollToTopTrigger

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Color.clear.frame(height: 0).id("top")
                        // Theme
                        themeCard

                        // Language
                        languageCard

                        // Tier Breakdown
                        tierBreakdownCard

                        // About
                        aboutCard
                    }
                    .padding()
                    .padding(.top, 8)
                }
                .onChange(of: scrollToTopTrigger) {
                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                }
                }
            }
            .navigationTitle(L("settings.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Theme

    @Bindable private var themeManager = ThemeManager.shared

    private var themeCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "moon.circle.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("settings.theme"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            Picker("", selection: $themeManager.appTheme) {
                Text(L("settings.system")).tag("system")
                Text(L("settings.light")).tag("light")
                Text(L("settings.dark")).tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Language

    @ObservedObject private var localization = LocalizationManager.shared

    private var languageCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(BrainRotTheme.neonBlue)
                Text(L("settings.language"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            Picker("", selection: $localization.appLanguage) {
                Text(L("settings.system")).tag("system")
                Text(L("settings.english")).tag("en")
                Text(L("settings.german")).tag("de")
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tier Breakdown

    private var tierBreakdownCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("settings.krakenTiers"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            Text(L("settings.krakenTiersDesc"))
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)

            VStack(spacing: 8) {
                tierRow(name: L("tier.zenMaster"), range: "0 - 4h", color: Color(red: 0.55, green: 0.88, blue: 0.70))
                tierRow(name: L("tier.casualScroller"), range: "4h - 6h", color: Color(red: 0.52, green: 0.82, blue: 0.78))
                tierRow(name: L("tier.doomscroller"), range: "6h - 8h", color: Color(red: 0.75, green: 0.62, blue: 0.88))
                tierRow(name: L("tier.brainrot"), range: "8h+", color: Color(red: 0.68, green: 0.65, blue: 0.63))
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
                Text(L("settings.about"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L("settings.aboutDesc1"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Text(L("settings.aboutDesc2"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
