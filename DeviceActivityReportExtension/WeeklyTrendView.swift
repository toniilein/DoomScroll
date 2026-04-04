import SwiftUI

struct WeeklyTrendView: View {
    let trendData: WeeklyTrendData

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(BrainRotTheme.neonPurple)
                    Text(L("trend.thisWeek"))
                        .font(.headline)
                        .foregroundColor(BrainRotTheme.textPrimary)
                }

                Spacer()

                if trendData.streakDays > 0 {
                    HStack(spacing: 3) {
                        Text("\u{1F525}")
                            .font(.system(size: 12))
                        Text("\(trendData.streakDays)d")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.neonOrange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BrainRotTheme.neonOrange.opacity(0.15))
                    .clipShape(Capsule())
                }

                HStack(spacing: 3) {
                    Image(systemName: trendData.trend.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(trendData.trend.label)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(trendData.trend.color)
            }

            HStack {
                Text(String(format: L("trend.total"), trendData.formattedWeeklyTotal))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(trendData.dailyScores.enumerated()), id: \.element.id) { index, day in
                    VStack(spacing: 4) {
                        Text(day.formattedDuration)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(day.isToday ? BrainRotTheme.textPrimary : BrainRotTheme.textSecondary)

                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    day.isToday
                                        ? AnyShapeStyle(BrainRotTheme.accentGradient)
                                        : AnyShapeStyle(BrainRotTheme.scoreColor(for: day.score).opacity(0.6))
                                )
                                .frame(height: max(6, CGFloat(day.score) / 100.0 * 80))

                            if index == trendData.bestDayIndex {
                                Circle()
                                    .fill(BrainRotTheme.neonGreen)
                                    .frame(width: 6, height: 6)
                                    .offset(y: -4)
                            } else if index == trendData.worstDayIndex {
                                Circle()
                                    .fill(BrainRotTheme.neonPink)
                                    .frame(width: 6, height: 6)
                                    .offset(y: -4)
                            }
                        }

                        Text(day.dayLabel)
                            .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                            .foregroundColor(day.isToday ? BrainRotTheme.textPrimary : BrainRotTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
