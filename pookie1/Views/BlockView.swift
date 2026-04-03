import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct BlockView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @StateObject private var blockingManager = BlockingManager.shared
    @State private var showEditor = false
    @State private var editingRoutine: BlockRoutine?
    @State private var editingLimit: UsageLimit?
    @State private var showQuickBlockPicker = false
    @State private var showUnblockConfirm = false
    @State private var reportID = UUID()

    #if !targetEnvironment(simulator)
    @State private var quickBlockSelection = FamilyActivitySelection()
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quickBlockCard

                    usageLimitsSection

                    if !activeRoutines.isEmpty {
                        activeNowSection
                    }

                    routinesSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(BrainRotTheme.background)
            // Extension as background — renders behind ScrollView content,
            // system still connects it so makeConfiguration runs for shield enforcement
            #if !targetEnvironment(simulator)
            .background(
                Group {
                    if !blockingManager.usageLimits.isEmpty {
                        DeviceActivityReport(.limitUsage, filter: todayFilter)
                            .id(reportID)
                            .frame(width: 300, height: 300)
                            .allowsHitTesting(false)
                    }
                }
            )
            #endif
            .navigationTitle("Shield")
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUnblockConfirm = true
                    } label: {
                        Text("Unblock All")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Unblock All Apps?", isPresented: $showUnblockConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Unblock All", role: .destructive) {
                    blockingManager.unblockEverything()
                }
            } message: {
                Text("This will disable all shields, routines, and usage limits.")
            }
            .onAppear {
                blockingManager.syncAllSchedules()
                syncAllLimitConfigs()
                #if !targetEnvironment(simulator)
                quickBlockSelection = blockingManager.loadQuickBlockSelection()
                #endif
                reportID = UUID()
            }
            .sheet(item: $editingLimit) { limit in
                LimitEditorView(
                    limit: limit,
                    onSave: { updated in
                        blockingManager.saveUsageLimit(updated)
                        syncAllLimitConfigs()
                        editingLimit = nil
                    },
                    onDelete: { toDelete in
                        blockingManager.deleteUsageLimit(toDelete)
                        syncAllLimitConfigs()
                        editingLimit = nil
                    }
                )
            }
            .sheet(isPresented: $showEditor) {
                RoutineEditorView(
                    routine: editingRoutine,
                    onSave: { routine in
                        blockingManager.saveRoutine(routine)
                        showEditor = false
                        editingRoutine = nil
                    },
                    onDelete: editingRoutine != nil ? { routine in
                        blockingManager.deleteRoutine(routine)
                        showEditor = false
                        editingRoutine = nil
                    } : nil
                )
            }
            #if !targetEnvironment(simulator)
            .familyActivityPicker(
                isPresented: $showQuickBlockPicker,
                selection: $quickBlockSelection
            )
            .onChange(of: quickBlockSelection) { _, newValue in
                blockingManager.saveQuickBlockSelection(newValue)
            }
            #endif
        }
    }

    // MARK: - Quick Block

    private var quickBlockCard: some View {
        let isBlocking = blockingManager.isQuickBlocking

        return HStack(spacing: 12) {
            Image(systemName: isBlocking ? "shield.checkered" : "shield.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    isBlocking
                        ? AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonGreen, BrainRotTheme.neonGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonPink, BrainRotTheme.neonOrange], startPoint: .top, endPoint: .bottom))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(isBlocking ? "Apps Blocked" : "Quick Block")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)

                Button { showQuickBlockPicker = true } label: {
                    HStack(spacing: 4) {
                        #if !targetEnvironment(simulator)
                        let apps = quickBlockSelection.applicationTokens.count
                        let cats = quickBlockSelection.categoryTokens.count
                        Text(apps > 0 || cats > 0
                             ? "\(apps) app\(apps == 1 ? "" : "s"), \(cats) categor\(cats == 1 ? "y" : "ies")"
                             : "Choose apps")
                        #else
                        Text("Choose apps")
                        #endif
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    blockingManager.toggleQuickBlock()
                }
            } label: {
                Text(isBlocking ? "Stop" : "Block")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        isBlocking
                            ? AnyShapeStyle(LinearGradient(colors: [Color.gray, Color.gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonPink, BrainRotTheme.neonOrange], startPoint: .leading, endPoint: .trailing))
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Usage Limits

    private var usageLimitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Usage Limits")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Button {
                    editingLimit = UsageLimit(name: "", limitMinutes: 60, isEnabled: false)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(BrainRotTheme.neonOrange)
                }
            }
            .padding(.horizontal, 4)

            if blockingManager.usageLimits.isEmpty {
                Button {
                    editingLimit = UsageLimit(name: "", limitMinutes: 60, isEnabled: false)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 18))
                            .foregroundColor(BrainRotTheme.neonOrange)
                        Text("Add a usage limit")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textSecondary)
                        Spacer()
                    }
                    .padding(14)
                    .background(BrainRotTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                ForEach(blockingManager.usageLimits) { limit in
                    limitCard(limit)
                }
            }
        }
    }

    private func limitCard(_ limit: UsageLimit) -> some View {
        Button { editingLimit = limit } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(limit.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                        .lineLimit(1)
                    Text("Limit: \(limit.formattedLimit)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Toggle("", isOn: Binding(
                    get: { limit.isEnabled },
                    set: { _ in
                        blockingManager.toggleUsageLimit(limit)
                        syncAllLimitConfigs()
                    }
                ))
                .labelsHidden()
                .tint(BrainRotTheme.neonOrange)
            }
            .padding(14)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Routines

    private var activeRoutines: [BlockRoutine] {
        let now = Calendar.current.dateComponents([.hour, .minute, .weekday], from: Date())
        let cur = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let weekday = now.weekday ?? 1
        return blockingManager.routines.filter { r in
            guard r.isEnabled else { return false }
            guard r.activeDays.contains(weekday) else { return false }
            let s = r.startHour * 60 + r.startMinute, e = r.endHour * 60 + r.endMinute
            return s <= e ? (cur >= s && cur < e) : (cur >= s || cur < e)
        }
    }

    private var activeNowSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(BrainRotTheme.neonPink).frame(width: 8, height: 8)
                Text("Active Now")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.neonPink)
            }
            ForEach(activeRoutines) { routine in
                HStack(spacing: 10) {
                    Image(systemName: "shield.fill").font(.system(size: 14)).foregroundColor(BrainRotTheme.neonPink)
                    Text(routine.name).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(BrainRotTheme.textPrimary)
                    Spacer()
                    Text("Until \(formatEndTime(routine))").font(.system(size: 11, weight: .medium)).foregroundColor(BrainRotTheme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(BrainRotTheme.neonPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrainRotTheme.neonPink.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Routines

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Routines")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Button {
                    editingRoutine = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(BrainRotTheme.neonPink)
                }
            }
            .padding(.horizontal, 4)
            ForEach(blockingManager.routines) { routine in
                routineCard(routine)
            }
        }
    }

    private func routineCard(_ routine: BlockRoutine) -> some View {
        let icon = routineIcon(routine.name)
        return Button {
            editingRoutine = routine
            showEditor = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(routine.isEnabled ? BrainRotTheme.neonPink.opacity(0.15) : BrainRotTheme.cardBorder)
                        .frame(width: 38, height: 38)
                    Text(icon).font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(BrainRotTheme.textPrimary)
                    HStack(spacing: 6) {
                        Label(routine.formattedTimeRange, systemImage: "clock")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(BrainRotTheme.textSecondary)
                        Text(weekdaySummary(routine.activeDays))
                            .font(.system(size: 11, weight: .medium)).foregroundColor(BrainRotTheme.textSecondary)
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { routine.isEnabled },
                    set: { _ in blockingManager.toggleRoutine(routine) }
                )).labelsHidden().tint(BrainRotTheme.neonPink)
            }
            .padding(12)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    #if !targetEnvironment(simulator)
    private var todayFilter: DeviceActivityFilter {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let interval = DateInterval(start: start, end: end)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }
    #endif

    private func syncAllLimitConfigs() {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.pookie1.shared"
        )?.appendingPathComponent("usageLimits.json") else { return }

        struct CodableLimit: Codable {
            let id: UUID
            let name: String
            let appSelectionData: Data?
            let limitMinutes: Int
            let isEnabled: Bool
            let activeDays: Set<Int>
        }

        let codable = blockingManager.usageLimits.map {
            CodableLimit(id: $0.id, name: $0.name, appSelectionData: $0.appSelectionData,
                         limitMinutes: $0.limitMinutes, isEnabled: $0.isEnabled, activeDays: $0.activeDays)
        }

        if let jsonData = try? JSONEncoder().encode(codable) {
            try? jsonData.write(to: url, options: .atomic)
        }
    }

    private func routineIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("morning") { return "\u{1F305}" }
        if l.contains("work") || l.contains("focus") { return "\u{1F4BC}" }
        if l.contains("night") || l.contains("evening") || l.contains("wind") { return "\u{1F319}" }
        if l.contains("bed") || l.contains("sleep") { return "\u{1F634}" }
        if l.contains("study") { return "\u{1F4DA}" }
        if l.contains("gym") || l.contains("exercise") || l.contains("fitness") { return "\u{1F3CB}\u{FE0F}" }
        if l.contains("meal") || l.contains("lunch") || l.contains("dinner") { return "\u{1F37D}\u{FE0F}" }
        return "\u{1F6E1}\u{FE0F}"
    }

    private func weekdaySummary(_ days: Set<Int>) -> String {
        if days.count == 7 { return "Every day" }
        if days == [2, 3, 4, 5, 6] { return "Weekdays" }
        if days == [1, 7] { return "Weekends" }
        let labels: [Int: String] = [1: "Su", 2: "Mo", 3: "Tu", 4: "We", 5: "Th", 6: "Fr", 7: "Sa"]
        let ordered = [2, 3, 4, 5, 6, 7, 1]
        return ordered.filter { days.contains($0) }.compactMap { labels[$0] }.joined(separator: " ")
    }

    private func formatEndTime(_ r: BlockRoutine) -> String {
        let h = r.endHour % 12 == 0 ? 12 : r.endHour % 12
        let p = r.endHour < 12 ? "AM" : "PM"
        return r.endMinute == 0 ? "\(h) \(p)" : "\(h):\(String(format: "%02d", r.endMinute)) \(p)"
    }
}
