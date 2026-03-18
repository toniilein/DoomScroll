import SwiftUI

struct TotalActivityView: View {
    let activityData: TotalActivityData

    @State private var selectedIndex: Int = 6
    @State private var expandedAppID: UUID? = nil

    private var currentDay: DayBreakdown {
        activityData.days[selectedIndex]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Day Selector Pills
                daySelectorBar
                    .padding(.horizontal, 8)

                // 2. Octopus Mascot + Tier Progress
                OctopusMascotView(
                    score: currentDay.score,
                    totalScreenTime: currentDay.formattedDuration,
                    totalDurationSeconds: currentDay.duration
                )
                .padding(.top, 4)

                // 3. Quick Stats Row
                QuickStatsRowView(
                    pickups: currentDay.pickups,
                    avgSessionMinutes: currentDay.pickups > 0 ? (currentDay.duration / 60.0) / Double(currentDay.pickups) : 0,
                    pickupFrequencyMinutes: currentDay.pickups > 0 ? (currentDay.duration > 0 ? (currentDay.duration / 60.0) / Double(currentDay.pickups) * 60 : 0) : 0
                )
                .padding(.horizontal)

                // 4. App Breakdown
                if !currentDay.apps.isEmpty {
                    appBreakdownSection
                        .padding(.horizontal)
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
        .onAppear {
            selectedIndex = activityData.selectedDayIndex
        }
    }

    // MARK: - Day Selector

    private var daySelectorBar: some View {
        HStack(spacing: 4) {
            ForEach(Array(activityData.days.enumerated()), id: \.element.id) { index, day in
                dayPill(day: day, index: index)
            }
        }
    }

    private func dayPill(day: DayBreakdown, index: Int) -> some View {
        let isSelected = index == selectedIndex
        let mood = OctopusMood.from(score: day.score)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = index
                expandedAppID = nil
                // Save selected offset so next render knows
                let shared = UserDefaults(suiteName: "group.pookie1.shared")
                shared?.set(day.id, forKey: "selectedDayOffset")
                shared?.synchronize()
            }
        } label: {
            VStack(spacing: 2) {
                // Mini octopus face
                ZStack {
                    Circle()
                        .fill(
                            day.hasData
                                ? RadialGradient(
                                    colors: [mood.bodyColor, mood.bodyColorDark],
                                    center: .init(x: 0.4, y: 0.35),
                                    startRadius: 2, endRadius: 12
                                )
                                : RadialGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    center: .center,
                                    startRadius: 2, endRadius: 12
                                )
                        )
                        .frame(width: 22, height: 22)

                    if day.hasData {
                        miniOctopusEyes(mood: mood)
                    } else {
                        HStack(spacing: 5) {
                            Capsule().fill(Color.white.opacity(0.6)).frame(width: 4, height: 1.5)
                            Capsule().fill(Color.white.opacity(0.6)).frame(width: 4, height: 1.5)
                        }
                        .offset(y: -1)
                    }
                }

                Text(day.dayNumber)
                    .font(.system(size: 13, weight: isSelected ? .black : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : BrainRotTheme.textPrimary)

                if day.hasData {
                    Text(day.formattedDuration)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(isSelected ? .white : mood.bodyColorDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Text("--")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.4))
                }

                if day.isToday {
                    Circle()
                        .fill(isSelected ? Color.white : BrainRotTheme.neonPink)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? (day.hasData
                        ? AnyShapeStyle(LinearGradient(
                            colors: [mood.bodyColor, mood.bodyColorDark],
                            startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(BrainRotTheme.accentGradient))
                    : AnyShapeStyle(BrainRotTheme.cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Mini Octopus Eyes

    @ViewBuilder
    private func miniOctopusEyes(mood: OctopusMood) -> some View {
        switch mood {
        case .ecstatic:
            HStack(spacing: 5) {
                Text("\u{2605}").font(.system(size: 6, weight: .bold)).foregroundColor(.white)
                Text("\u{2605}").font(.system(size: 6, weight: .bold)).foregroundColor(.white)
            }.offset(y: -1)
        case .happy:
            HStack(spacing: 5) {
                Capsule().fill(Color.white).frame(width: 4.5, height: 2)
                Capsule().fill(Color.white).frame(width: 4.5, height: 2)
            }.offset(y: -1)
        case .neutral:
            HStack(spacing: 5) {
                Circle().fill(Color.white).frame(width: 4.5, height: 4.5)
                Circle().fill(Color.white).frame(width: 4.5, height: 4.5)
            }.offset(y: -1)
        case .sad:
            HStack(spacing: 5) {
                Circle().fill(Color.white).frame(width: 4, height: 4)
                Circle().fill(Color.white).frame(width: 4, height: 4)
            }
        case .distressed:
            HStack(spacing: 4) {
                Text("@").font(.system(size: 5, weight: .heavy)).foregroundColor(.white)
                Text("@").font(.system(size: 5, weight: .heavy)).foregroundColor(.white)
            }.offset(y: -1)
        case .zombie:
            HStack(spacing: 4) {
                Text("x").font(.system(size: 6, weight: .black)).foregroundColor(.white.opacity(0.8))
                Text("x").font(.system(size: 6, weight: .black)).foregroundColor(.white.opacity(0.8))
            }.offset(y: -1)
        }
    }

    // MARK: - App Breakdown

    private var appBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text("App Breakdown")
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(currentDay.apps.count) apps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(currentDay.apps.enumerated()), id: \.element.id) { index, app in
                appRow(app: app, rank: index + 1)

                if index < currentDay.apps.count - 1 {
                    Divider()
                        .padding(.leading, 60)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func appRow(app: AppUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == app.id

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : app.id
                }
            } label: {
                HStack(spacing: 12) {
                    appIcon(name: app.displayName, rank: rank)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 9))
                            Text("\(app.numberOfPickups) pickups")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    Text(app.formattedDuration)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(appColor(for: app))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedDetail(app: app)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func expandedDetail(app: AppUsageData) -> some View {
        let percentage = currentDay.duration > 0
            ? (app.duration / currentDay.duration) * 100
            : 0
        let avgSession = app.numberOfPickups > 0
            ? app.duration / Double(app.numberOfPickups)
            : app.duration

        return VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Screen Time Share")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(appColor(for: app))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(appColor(for: app))
                            .frame(width: geo.size.width * min(percentage / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }

            HStack(spacing: 0) {
                miniStat(icon: "clock.fill", title: "Duration", value: app.formattedDuration)
                miniStat(icon: "hand.tap.fill", title: "Pickups", value: "\(app.numberOfPickups)")
                miniStat(icon: "timer", title: "Avg Session", value: BrainRotCalculator.formatDuration(avgSession))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 2)
        .background(appColor(for: app).opacity(0.04))
    }

    private func miniStat(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(BrainRotTheme.textSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func appIcon(name: String, rank: Int) -> some View {
        let letter = String(name.prefix(1)).uppercased()
        let colors: [Color] = [BrainRotTheme.neonPink, BrainRotTheme.neonPurple, BrainRotTheme.neonOrange, BrainRotTheme.neonBlue, BrainRotTheme.neonGreen]
        let color = rank <= colors.count ? colors[rank - 1] : BrainRotTheme.textSecondary

        return ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 36, height: 36)
            Text(letter)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private func appColor(for app: AppUsageData) -> Color {
        BrainRotTheme.scoreColor(for: BrainRotCalculator.score(totalMinutes: app.duration / 60.0))
    }
}
