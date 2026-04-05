import SwiftUI

struct TotalActivityView: View {
    let activityData: TotalActivityData

    @State private var selectedIndex: Int = 6
    @State private var expandedAppID: UUID? = nil
    @State private var showCategories: Bool = false

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

                // 4. Breakdown toggle + section
                if !currentDay.apps.isEmpty || !currentDay.categories.isEmpty {
                    breakdownToggle
                        .padding(.horizontal)

                    if showCategories {
                        categoryBreakdownSection
                            .padding(.horizontal)
                    } else {
                        appBreakdownSection
                            .padding(.horizontal)
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding(.vertical, 8)
        }
        .background(BrainRotTheme.background)
        .preferredColorScheme(SharedTheme.colorScheme)
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
        let mood = OctopusMood.from(minutes: day.duration / 60.0)

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
        case .sad:
            HStack(spacing: 5) {
                Circle().fill(Color.white).frame(width: 4, height: 4)
                Circle().fill(Color.white).frame(width: 4, height: 4)
            }
        case .zombie:
            HStack(spacing: 4) {
                Text("x").font(.system(size: 6, weight: .black)).foregroundColor(.white.opacity(0.8))
                Text("x").font(.system(size: 6, weight: .black)).foregroundColor(.white.opacity(0.8))
            }.offset(y: -1)
        }
    }

    // MARK: - Breakdown Toggle

    private var breakdownToggle: some View {
        Picker("", selection: $showCategories) {
            Text(L("breakdown.appBreakdown")).tag(false)
            Text(L("breakdown.categoryBreakdown")).tag(true)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("breakdown.categoryBreakdown"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(currentDay.categories.count) \(L("breakdown.groups"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(currentDay.categories.enumerated()), id: \.element.id) { index, category in
                categoryRow(category: category, rank: index + 1)

                if index < currentDay.categories.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func categoryRow(category: CategoryUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == category.id

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : category.id
                }
            } label: {
                HStack(spacing: 12) {
                    categoryIcon(name: category.categoryName, rank: rank)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.categoryName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "app.fill")
                                .font(.system(size: 9))
                            Text("\(category.apps.count) \(L("breakdown.apps"))")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    Text(category.formattedDuration)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.categoryColor(for: category.categoryName))

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
                categoryExpandedDetail(category: category, rank: rank)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func categoryExpandedDetail(category: CategoryUsageData, rank: Int) -> some View {
        let percentage = currentDay.duration > 0
            ? (category.duration / currentDay.duration) * 100
            : 0
        let avgSession = category.pickups > 0
            ? category.duration / Double(category.pickups)
            : category.duration
        let color = BrainRotTheme.categoryColor(for: category.categoryName)

        return VStack(spacing: 10) {
            // Stats row
            HStack(spacing: 0) {
                miniStat(icon: "clock.fill", title: L("breakdown.duration"), value: category.formattedDuration)
                miniStat(icon: "hand.tap.fill", title: L("breakdown.pickups"), value: "\(category.pickups)")
                miniStat(icon: "timer", title: L("breakdown.avgSession"), value: BrainRotCalculator.formatDuration(avgSession))
            }

            // Percentage bar
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(L("breakdown.screenTimeShare"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geo.size.width * min(percentage / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // App list within category
            if !category.apps.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text(L("common.apps"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .padding(.bottom, 6)

                    ForEach(category.apps) { app in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(color.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text(app.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(app.formattedDuration)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 2)
        .background(color.opacity(0.04))
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

    private func categoryIcon(name: String, rank: Int) -> some View {
        let icon = categorySystemIcon(name)
        let color = BrainRotTheme.categoryColor(for: name)

        return ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private func categorySystemIcon(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("social") { return "bubble.left.and.bubble.right.fill" }
        if lower.contains("entertainment") || lower.contains("video") { return "play.tv.fill" }
        if lower.contains("game") { return "gamecontroller.fill" }
        if lower.contains("productivity") { return "briefcase.fill" }
        if lower.contains("education") { return "graduationcap.fill" }
        if lower.contains("health") || lower.contains("fitness") { return "heart.fill" }
        if lower.contains("shopping") { return "cart.fill" }
        if lower.contains("news") || lower.contains("reading") { return "newspaper.fill" }
        if lower.contains("photo") || lower.contains("creative") { return "camera.fill" }
        if lower.contains("music") { return "music.note" }
        if lower.contains("travel") || lower.contains("navigation") { return "map.fill" }
        if lower.contains("finance") || lower.contains("business") { return "chart.line.uptrend.xyaxis" }
        if lower.contains("utility") || lower.contains("utilities") { return "wrench.fill" }
        if lower.contains("communication") || lower.contains("message") { return "message.fill" }
        return "square.grid.2x2.fill"
    }

    private func categoryColor(rank: Int) -> Color {
        let colors: [Color] = [BrainRotTheme.neonPink, BrainRotTheme.neonPurple, BrainRotTheme.neonOrange, BrainRotTheme.neonBlue, BrainRotTheme.neonGreen]
        return rank <= colors.count ? colors[rank - 1] : BrainRotTheme.textSecondary
    }

    private func appCategoryColor(for app: AppUsageData) -> Color {
        BrainRotTheme.categoryColor(for: app.categoryName)
    }

    // MARK: - App Breakdown

    private var appBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "app.fill")
                    .foregroundColor(BrainRotTheme.neonPurple)
                Text(L("breakdown.appBreakdown"))
                    .font(.headline)
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Text("\(currentDay.apps.count) \(L("breakdown.apps"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            ForEach(Array(currentDay.apps.enumerated()), id: \.element.id) { index, app in
                overviewAppRow(app: app, rank: index + 1)

                if index < currentDay.apps.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func overviewAppRow(app: AppUsageData, rank: Int) -> some View {
        let isExpanded = expandedAppID == app.id
        let color = appCategoryColor(for: app)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedAppID = isExpanded ? nil : app.id
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        Text(String(app.displayName.first(where: { $0.isLetter }) ?? "?").uppercased())
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 9))
                            Text("\(app.numberOfPickups) \(L("breakdown.pickups"))")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    Text(app.formattedDuration)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(color)

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
                overviewAppExpandedDetail(app: app, rank: rank)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func overviewAppExpandedDetail(app: AppUsageData, rank: Int) -> some View {
        let percentage = currentDay.duration > 0
            ? (app.duration / currentDay.duration) * 100 : 0
        let avgSession = app.numberOfPickups > 0
            ? app.duration / Double(app.numberOfPickups) : app.duration
        let color = appCategoryColor(for: app)

        return VStack(spacing: 10) {
            HStack(spacing: 0) {
                miniStat(icon: "clock.fill", title: L("breakdown.duration"), value: app.formattedDuration)
                miniStat(icon: "hand.tap.fill", title: L("breakdown.pickups"), value: "\(app.numberOfPickups)")
                miniStat(icon: "timer", title: L("breakdown.avgSession"), value: BrainRotCalculator.formatDuration(avgSession))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(L("breakdown.screenTimeShare"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geo.size.width * min(percentage / 100, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 2)
        .background(color.opacity(0.04))
    }
}
