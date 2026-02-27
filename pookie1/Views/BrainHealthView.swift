import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct BrainHealthView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var selectedDate = Date.now

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if screenTimeManager.hasSelectedApps {
                            #if targetEnvironment(simulator)
                            simulatorBrainHealth
                            #else
                            let filter = DeviceActivityFilter(
                                segment: .daily(
                                    during: Calendar.current.dateInterval(of: .day, for: selectedDate)!
                                ),
                                users: .all,
                                devices: .init([.iPhone, .iPad]),
                                applications: screenTimeManager.activitySelection.applicationTokens,
                                categories: screenTimeManager.activitySelection.categoryTokens
                            )
                            DeviceActivityReport(.brainHealth, filter: filter)
                                .frame(minHeight: 600)
                            #endif
                        } else {
                            emptyState
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Brain Health")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("\u{1F9E0}")
                .font(.system(size: 60))
            Text("Track your brain health")
                .font(.title2.bold())
                .foregroundColor(BrainRotTheme.textPrimary)
            Text("Select apps in the Apps tab to start monitoring your doomscroll habits")
                .font(.body)
                .foregroundColor(BrainRotTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Simulator Mock

    #if targetEnvironment(simulator)
    private var simulatorBrainHealth: some View {
        VStack(spacing: 28) {
            // Main brainrot score
            brainRotScoreSection

            // Health status card
            healthStatusCard

            // Doomscroll metrics
            doomscrollMetrics

            // Daily breakdown
            dailyBreakdown

            // Tips
            brainHealthTips
        }
        .padding(.horizontal)
    }

    private var brainRotScoreSection: some View {
        VStack(spacing: 8) {
            Text("YOUR DOOMSCROLL SCORE")
                .font(.caption.bold())
                .foregroundColor(BrainRotTheme.textSecondary)
                .tracking(2)

            BrainRotScoreView(
                score: 72,
                totalScreenTime: "2h 45m today"
            )

            Text(BrainRotTheme.scoreEmoji(for: 72))
                .font(.system(size: 32))
        }
        .padding(.vertical, 8)
    }

    private var healthStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .font(.title2)
                    .foregroundColor(BrainRotTheme.neonPink)
                Text("Brain Health Status")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(healthBarColor(index: i, score: 72))
                        .frame(height: 8)
                        .clipShape(
                            .rect(
                                topLeadingRadius: i == 0 ? 4 : 0,
                                bottomLeadingRadius: i == 0 ? 4 : 0,
                                bottomTrailingRadius: i == 4 ? 4 : 0,
                                topTrailingRadius: i == 4 ? 4 : 0
                            )
                        )
                }
            }

            HStack {
                Text("Healthy")
                    .font(.caption2)
                    .foregroundColor(BrainRotTheme.neonGreen)
                Spacer()
                Text("Cooked")
                    .font(.caption2)
                    .foregroundColor(BrainRotTheme.neonPink)
            }

            Text("Your screen time is above average today. Consider taking a break from social media.")
                .font(.subheadline)
                .foregroundColor(BrainRotTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.neonPink.opacity(0.3), lineWidth: 1)
        )
    }

    private var doomscrollMetrics: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("Doomscroll Metrics")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard(title: "Pickups", value: "47", icon: "iphone.gen3", color: BrainRotTheme.neonPurple)
                metricCard(title: "Longest Session", value: "38m", icon: "timer", color: BrainRotTheme.neonPink)
                metricCard(title: "First Pickup", value: "7:12 AM", icon: "sunrise.fill", color: BrainRotTheme.neonBlue)
                metricCard(title: "Notifications", value: "124", icon: "bell.badge.fill", color: BrainRotTheme.neonGreen)
            }
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var dailyBreakdown: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(BrainRotTheme.neonBlue)
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 8) {
                dayBar(day: "Mon", hours: 1.5, maxHours: 4)
                dayBar(day: "Tue", hours: 2.2, maxHours: 4)
                dayBar(day: "Wed", hours: 3.1, maxHours: 4)
                dayBar(day: "Thu", hours: 1.8, maxHours: 4)
                dayBar(day: "Fri", hours: 2.7, maxHours: 4)
                dayBar(day: "Sat", hours: 3.8, maxHours: 4)
                dayBar(day: "Sun", hours: 2.8, maxHours: 4, isToday: true)
            }
            .frame(height: 120)

            HStack {
                Text("Weekly avg: 2h 33m")
                    .font(.caption)
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                    Text("12% vs last week")
                        .font(.caption)
                }
                .foregroundColor(BrainRotTheme.neonPink)
            }
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var brainHealthTips: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(BrainRotTheme.neonGreen)
                Text("Brain Health Tips")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
            }

            tipRow(emoji: "\u{1F33F}", text: "Try a 15-minute phone-free walk after lunch")
            tipRow(emoji: "\u{1F4F5}", text: "Set app limits for your top doomscroll apps")
            tipRow(emoji: "\u{1F3AF}", text: "Goal: Get your score under 50 this week")
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.neonGreen.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Helper Views

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(BrainRotTheme.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayBar(day: String, hours: Double, maxHours: Double, isToday: Bool = false) -> some View {
        VStack(spacing: 4) {
            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isToday
                    ? BrainRotTheme.neonPink
                    : BrainRotTheme.neonPurple.opacity(0.6)
                )
                .frame(height: CGFloat(hours / maxHours) * 80)

            Text(day)
                .font(.caption2)
                .foregroundColor(
                    isToday
                    ? BrainRotTheme.neonPink
                    : BrainRotTheme.textSecondary
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func tipRow(emoji: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(BrainRotTheme.textSecondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func healthBarColor(index: Int, score: Int) -> Color {
        let filledSegments = score / 20
        if index < filledSegments {
            switch index {
            case 0: return BrainRotTheme.neonGreen
            case 1: return BrainRotTheme.neonBlue
            case 2: return BrainRotTheme.neonPurple
            case 3: return BrainRotTheme.neonPink
            default: return BrainRotTheme.neonPink
            }
        } else if index == filledSegments {
            return BrainRotTheme.neonPurple.opacity(0.4)
        }
        return Color.white.opacity(0.1)
    }
    #endif
}
