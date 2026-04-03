import SwiftUI
import Combine
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
    @State private var blockPulse = false
    @State private var showQuickBlockPicker = false
    @State private var showUnblockConfirm = false
    @State private var usageRefreshTick = 0

    #if !targetEnvironment(simulator)
    @State private var quickBlockSelection = FamilyActivitySelection()
    #endif

    private let refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        quickBlockSection

                        if !activeRoutines.isEmpty {
                            activeNowSection
                        }

                        limitsSection

                        routinesSection

                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
            }
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
            }
            .onReceive(refreshTimer) { _ in
                usageRefreshTick += 1
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

    private var quickBlockSection: some View {
        let isBlocking = blockingManager.isQuickBlocking

        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isBlocking
                                ? [BrainRotTheme.neonGreen.opacity(0.2), BrainRotTheme.neonGreen.opacity(0.05)]
                                : [BrainRotTheme.neonPink.opacity(0.15), BrainRotTheme.neonPink.opacity(0.05)],
                            center: .center,
                            startRadius: 20, endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(blockPulse ? 1.05 : 0.95)

                Image(systemName: isBlocking ? "shield.checkered" : "shield.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        isBlocking
                            ? AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonGreen, BrainRotTheme.neonGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonPink, BrainRotTheme.neonOrange], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: (isBlocking ? BrainRotTheme.neonGreen : BrainRotTheme.neonPink).opacity(0.4), radius: 10, y: 4)
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    blockingManager.toggleQuickBlock()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isBlocking ? "shield.slash.fill" : "shield.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(isBlocking ? "Unblock Apps" : "Block Apps Now")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isBlocking
                        ? AnyShapeStyle(LinearGradient(colors: [Color.gray, Color.gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(LinearGradient(colors: [BrainRotTheme.neonPink, BrainRotTheme.neonOrange], startPoint: .leading, endPoint: .trailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button { showQuickBlockPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apps.iphone").font(.system(size: 14))
                    #if !targetEnvironment(simulator)
                    let apps = quickBlockSelection.applicationTokens.count
                    let cats = quickBlockSelection.categoryTokens.count
                    Text(apps > 0 || cats > 0
                         ? "\(apps) app\(apps == 1 ? "" : "s"), \(cats) categor\(cats == 1 ? "y" : "ies")"
                         : "Choose apps to block")
                    #else
                    Text("Choose apps to block")
                    #endif
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(BrainRotTheme.cardBorder.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if isBlocking {
                Text("Your selected apps are currently blocked")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.neonGreen)
            }
        }
        .padding(20)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { blockPulse = true }
        }
    }

    // MARK: - Active Routines

    private var activeRoutines: [BlockRoutine] {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let cur = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        return blockingManager.routines.filter { r in
            guard r.isEnabled else { return false }
            let s = r.startHour * 60 + r.startMinute, e = r.endHour * 60 + r.endMinute
            return s <= e ? (cur >= s && cur < e) : (cur >= s || cur < e)
        }
    }

    private var activeNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(BrainRotTheme.neonPink).frame(width: 8, height: 8)
                Text("Active Now")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.neonPink)
            }
            ForEach(activeRoutines) { routine in
                HStack(spacing: 10) {
                    Image(systemName: "shield.fill").font(.system(size: 16)).foregroundColor(BrainRotTheme.neonPink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(routine.name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(BrainRotTheme.textPrimary)
                        Text("Until \(formatEndTime(routine))").font(.system(size: 11, weight: .medium)).foregroundColor(BrainRotTheme.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(BrainRotTheme.neonPink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BrainRotTheme.neonPink.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Usage Limits

    private var limitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Usage Limits")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Button {
                    editingLimit = UsageLimit(name: "", limitMinutes: 60, isEnabled: false)
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(BrainRotTheme.neonOrange)
                }
            }
            .padding(.horizontal, 4)

            // Single report processes ALL limits at once — writes per-limit usage to UserDefaults
            #if !targetEnvironment(simulator)
            DeviceActivityReport(.limitUsage, filter: todayAllAppsFilter)
                .frame(minHeight: 2)
            #endif

            if blockingManager.usageLimits.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "hourglass").font(.system(size: 20)).foregroundColor(BrainRotTheme.textSecondary.opacity(0.4))
                    Text("Set daily time limits for app groups")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(blockingManager.usageLimits) { limit in
                    limitCard(limit)
                }
            }
        }
    }

    private func limitCard(_ limit: UsageLimit) -> some View {
        let usage = usageForLimit(limit)

        return Button { editingLimit = limit } label: {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(limit.isEnabled ? BrainRotTheme.neonOrange.opacity(0.15) : BrainRotTheme.cardBorder)
                            .frame(width: 40, height: 40)
                        Image(systemName: limitIcon(limit.name))
                            .font(.system(size: 17))
                            .foregroundColor(limit.isEnabled ? BrainRotTheme.neonOrange : BrainRotTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(limit.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)

                        HStack(spacing: 4) {
                            Text(usage.formattedUsage)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundColor(usage.exceeded ? .red : BrainRotTheme.neonOrange)

                            Text("/ \(limit.formattedLimit)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)

                            if usage.exceeded {
                                HStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 8))
                                    Text("Exceeded")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.red)
                                .padding(.leading, 2)
                            }
                        }
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { limit.isEnabled },
                        set: { _ in
                            blockingManager.toggleUsageLimit(limit)
                            syncAllLimitConfigs()
                        }
                    ))
                    .labelsHidden()
                    .tint(BrainRotTheme.neonOrange)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textSecondary.opacity(0.5))
                }

                // Native progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(BrainRotTheme.cardBorder)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(usage.exceeded ? Color.red : BrainRotTheme.neonOrange)
                            .frame(width: geo.size.width * usage.progress)
                    }
                }
                .frame(height: 4)
            }
            .padding(14)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // Read per-limit usage from shared UserDefaults (written by extension)
    private func usageForLimit(_ limit: UsageLimit) -> (formattedUsage: String, exceeded: Bool, progress: Double) {
        _ = usageRefreshTick // trigger re-read on timer

        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let usedSeconds = shared?.double(forKey: "limit_\(limit.id.uuidString)_usedSeconds") ?? 0
        let usedMinutes = usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(limit.limitMinutes)
        let progress = min(1.0, usedMinutes / Double(max(1, limit.limitMinutes)))

        let h = Int(usedMinutes) / 60
        let m = Int(usedMinutes) % 60
        let formatted: String
        if h > 0 && m > 0 { formatted = "\(h)h \(m)m" }
        else if h > 0 { formatted = "\(h)h" }
        else { formatted = "\(m)m" }

        return (formatted, exceeded, progress)
    }

    private func syncAllLimitConfigs() {
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        let allIds = blockingManager.usageLimits.map { $0.id.uuidString }
        shared?.set(allIds, forKey: "allLimitIds")

        for limit in blockingManager.usageLimits {
            let id = limit.id.uuidString
            shared?.set(limit.limitMinutes, forKey: "limit_\(id)_minutes")
            shared?.set(limit.isEnabled, forKey: "limit_\(id)_enabled")
            shared?.set(limit.appSelectionData, forKey: "limit_\(id)_selectionData")
        }
        shared?.synchronize()
    }

    #if !targetEnvironment(simulator)
    private var todayAllAppsFilter: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: .now)
            ?? DateInterval(start: .now, duration: 86400)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }
    #endif

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
                        .frame(width: 42, height: 42)
                    Text(icon).font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(routine.name).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(BrainRotTheme.textPrimary)
                    HStack(spacing: 8) {
                        Label(routine.formattedTimeRange, systemImage: "clock")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(BrainRotTheme.textSecondary)
                        Text(routine.selectionSummary)
                            .font(.system(size: 11, weight: .medium)).foregroundColor(BrainRotTheme.textSecondary).lineLimit(1)
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { routine.isEnabled },
                    set: { _ in blockingManager.toggleRoutine(routine) }
                )).labelsHidden().tint(BrainRotTheme.neonPink)
            }
            .padding(14)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func limitIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("social") { return "person.2.fill" }
        if l.contains("game") || l.contains("gaming") { return "gamecontroller.fill" }
        if l.contains("entertainment") || l.contains("video") || l.contains("stream") { return "play.tv.fill" }
        if l.contains("news") || l.contains("read") { return "newspaper.fill" }
        if l.contains("shop") || l.contains("buy") { return "cart.fill" }
        if l.contains("product") || l.contains("work") { return "briefcase.fill" }
        if l.contains("message") || l.contains("chat") { return "message.fill" }
        if l.contains("music") || l.contains("audio") { return "music.note" }
        if l.contains("photo") || l.contains("camera") { return "camera.fill" }
        return "hourglass"
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

    private func formatEndTime(_ r: BlockRoutine) -> String {
        let h = r.endHour % 12 == 0 ? 12 : r.endHour % 12
        let p = r.endHour < 12 ? "AM" : "PM"
        return r.endMinute == 0 ? "\(h) \(p)" : "\(h):\(String(format: "%02d", r.endMinute)) \(p)"
    }
}
