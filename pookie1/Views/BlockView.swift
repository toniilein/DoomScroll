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
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        pageHeader
                        quickBlockHero
                        usageLimitsSection
                        routinesSection
                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }

                // Hidden extension outside ScrollView — runs makeConfiguration for shields
                #if !targetEnvironment(simulator)
                if !blockingManager.usageLimits.isEmpty {
                    DeviceActivityReport(.limitUsage, filter: todayFilter)
                        .id(reportID)
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                        .clipped()
                        .allowsHitTesting(false)
                }
                #endif
            }
            .background(BrainRotTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 14))
                            .foregroundColor(BrainRotTheme.neonPink)
                        Text("DOOMSCROLL")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUnblockConfirm = true
                    } label: {
                        Text("Unblock All")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
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

    // MARK: - Page Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Shield")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
            Text("Your digital immune system. Stronger than your willpower.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
        }
    }

    // MARK: - Quick Block Hero

    private var quickBlockHero: some View {
        let isBlocking = blockingManager.isQuickBlocking

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick Block")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Text("Going down a rabbit hole?\nCut the cord instantly.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: isBlocking ? "bolt.shield.fill" : "bolt.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrainRotTheme.neonPink, BrainRotTheme.neonOrange],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    blockingManager.toggleQuickBlock()
                }
            } label: {
                Text(isBlocking ? "Unblock Apps" : "Panic Button")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isBlocking
                            ? AnyShapeStyle(LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonPink, BrainRotTheme.neonOrange], startPoint: .leading, endPoint: .trailing))
                    )
                    .clipShape(Capsule())
                    .shadow(color: (isBlocking ? Color.gray : BrainRotTheme.neonPink).opacity(0.3), radius: 8, y: 4)
            }

            Button { showQuickBlockPicker = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "apps.iphone").font(.system(size: 13))
                    #if !targetEnvironment(simulator)
                    let apps = quickBlockSelection.applicationTokens.count
                    let cats = quickBlockSelection.categoryTokens.count
                    Text(apps > 0 || cats > 0
                         ? "\(apps) app\(apps == 1 ? "" : "s"), \(cats) categor\(cats == 1 ? "y" : "ies") selected"
                         : "Choose apps to block")
                    #else
                    Text("Choose apps to block")
                    #endif
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
            }
        }
        .padding(24)
        .background(BrainRotTheme.neonPink.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(BrainRotTheme.neonPink.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Usage Limits

    private var usageLimitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("Usage Limits")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Button {
                    editingLimit = UsageLimit(name: "", limitMinutes: 60, isEnabled: false)
                } label: {
                    Text("Add Limit")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.neonPink)
                }
            }
            .padding(.horizontal, 2)

            if blockingManager.usageLimits.isEmpty {
                emptyLimitCard
            } else {
                ForEach(blockingManager.usageLimits) { limit in
                    limitCard(limit)
                }
            }
        }
    }

    private var emptyLimitCard: some View {
        Button {
            editingLimit = UsageLimit(name: "", limitMinutes: 60, isEnabled: false)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(BrainRotTheme.cardBorder)
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a usage limit")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Text("Set daily time limits for app groups")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                Spacer()
            }
            .padding(18)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func limitCard(_ limit: UsageLimit) -> some View {
        Button { editingLimit = limit } label: {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(BrainRotTheme.background)
                            .frame(width: 48, height: 48)
                        Image(systemName: limitIcon(limit.name))
                            .font(.system(size: 18))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    // Name + limit info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(limit.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)
                        Text("\(limit.formattedLimit) daily limit")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }

                    Spacer()

                    // Toggle
                    Toggle("", isOn: Binding(
                        get: { limit.isEnabled },
                        set: { _ in
                            blockingManager.toggleUsageLimit(limit)
                            syncAllLimitConfigs()
                        }
                    ))
                    .labelsHidden()
                    .tint(BrainRotTheme.neonPurple)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 12)

                // Progress bar placeholder — shows track, actual fill from extension
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BrainRotTheme.cardBorder)
                        .frame(height: 4)
                }
                .frame(height: 4)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Block Routines

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("Block Routines")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Spacer()
                Button {
                    editingRoutine = nil
                    showEditor = true
                } label: {
                    Text("Schedule")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(BrainRotTheme.neonPink)
                }
            }
            .padding(.horizontal, 2)

            if !activeRoutines.isEmpty {
                activeNowBanner
            }

            ForEach(blockingManager.routines) { routine in
                routineCard(routine)
            }
        }
    }

    private var activeNowBanner: some View {
        HStack(spacing: 8) {
            Circle().fill(BrainRotTheme.neonPink).frame(width: 8, height: 8)
            Text(activeRoutines.map(\.name).joined(separator: ", "))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.neonPink)
                .lineLimit(1)
            Spacer()
            Text("Active Now")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.neonPink.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(BrainRotTheme.neonPink.opacity(0.06))
        .clipShape(Capsule())
    }

    private func routineCard(_ routine: BlockRoutine) -> some View {
        Button {
            editingRoutine = routine
            showEditor = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: routineSystemIcon(routine.name))
                    .font(.system(size: 26))
                    .foregroundColor(routine.isEnabled ? BrainRotTheme.neonPurple : BrainRotTheme.textSecondary.opacity(0.4))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(routine.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(routine.isEnabled ? BrainRotTheme.textPrimary : BrainRotTheme.textPrimary.opacity(0.5))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(routine.formattedTimeRange)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(routine.isEnabled ? BrainRotTheme.textSecondary : BrainRotTheme.textSecondary.opacity(0.5))
                        HStack(spacing: 2) {
                            ForEach([(2,"M"),(3,"T"),(4,"W"),(5,"T"),(6,"F"),(7,"S"),(1,"S")], id: \.0) { weekday, label in
                                Text(label)
                                    .font(.system(size: 8, weight: .bold, design: .rounded))
                                    .foregroundColor(routine.activeDays.contains(weekday)
                                        ? (routine.isEnabled ? BrainRotTheme.neonPurple : BrainRotTheme.textSecondary)
                                        : BrainRotTheme.textSecondary.opacity(0.25))
                            }
                        }
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { routine.isEnabled },
                    set: { _ in blockingManager.toggleRoutine(routine) }
                ))
                .labelsHidden()
                .tint(BrainRotTheme.neonPurple)
            }
            .padding(16)
            .background(BrainRotTheme.cardBackground.opacity(routine.isEnabled ? 1 : 0.7))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(routine.isEnabled ? 0.04 : 0.02), radius: 8, y: 2)
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

    // MARK: - Helpers

    private func limitIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("all") { return "square.grid.2x2" }
        if l.contains("social") { return "arrowshape.turn.up.right" }
        if l.contains("game") || l.contains("gaming") { return "gamecontroller" }
        if l.contains("entertainment") || l.contains("video") || l.contains("stream") { return "play.tv" }
        if l.contains("news") || l.contains("read") { return "newspaper" }
        if l.contains("shop") || l.contains("buy") { return "cart" }
        if l.contains("message") || l.contains("chat") { return "message" }
        if l.contains("music") || l.contains("audio") { return "music.note" }
        return "square.grid.2x2"
    }

    private func routineSystemIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("morning") { return "sun.max.fill" }
        if l.contains("work") || l.contains("focus") { return "briefcase.fill" }
        if l.contains("night") || l.contains("evening") || l.contains("wind") { return "moon.fill" }
        if l.contains("bed") || l.contains("sleep") { return "bed.double.fill" }
        if l.contains("study") { return "book.fill" }
        if l.contains("gym") || l.contains("exercise") || l.contains("fitness") { return "figure.run" }
        if l.contains("meal") || l.contains("lunch") || l.contains("dinner") { return "fork.knife" }
        return "shield.fill"
    }

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
}
