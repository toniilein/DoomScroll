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
    @State private var blockPulse = false
    @State private var showQuickBlockPicker = false

    #if !targetEnvironment(simulator)
    @State private var quickBlockSelection = FamilyActivitySelection()
    #endif

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

                        addRoutineButton

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
                        blockingManager.unblockEverything()
                    } label: {
                        Text("Unblock All")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                }
            }
            .onAppear {
                blockingManager.syncAllSchedules()
                #if !targetEnvironment(simulator)
                quickBlockSelection = blockingManager.loadQuickBlockSelection()
                #endif
            }
            .sheet(item: $editingLimit) { limit in
                LimitEditorView(
                    limit: limit,
                    onSave: { updated in
                        blockingManager.saveUsageLimit(updated)
                        editingLimit = nil
                    },
                    onDelete: { toDelete in
                        blockingManager.deleteUsageLimit(toDelete)
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

            // Overall usage summary
            #if !targetEnvironment(simulator)
            DeviceActivityReport(.usageSummary, filter: screenTimeManager.filterForDate(.now))
                .frame(minHeight: 60)
            #endif
        }
    }

    private func limitCard(_ limit: UsageLimit) -> some View {
        VStack(spacing: 10) {
            // Header: icon + name + toggle
            HStack(spacing: 12) {
                Button { editingLimit = limit } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(limit.isEnabled ? BrainRotTheme.neonOrange.opacity(0.15) : BrainRotTheme.cardBorder)
                                .frame(width: 42, height: 42)
                            Image(systemName: "hourglass")
                                .font(.system(size: 18))
                                .foregroundColor(limit.isEnabled ? BrainRotTheme.neonOrange : BrainRotTheme.textSecondary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(limit.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                            HStack(spacing: 6) {
                                Text("Limit: \(limit.formattedLimit)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(BrainRotTheme.neonOrange)
                                Text(limit.selectionSummary)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(BrainRotTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { limit.isEnabled },
                    set: { _ in blockingManager.toggleUsageLimit(limit) }
                ))
                .labelsHidden()
                .tint(BrainRotTheme.neonOrange)
            }

            // Live usage from extension — filter scoped to this limit's selected apps
            #if !targetEnvironment(simulator)
            if limit.isEnabled {
                DeviceActivityReport(.limitUsage, filter: filterForLimit(limit))
                    .frame(height: 36)
                    .onAppear {
                        // Tell extension which limit this report is for + its config
                        let shared = UserDefaults(suiteName: "group.pookie1.shared")
                        shared?.set(limit.id.uuidString, forKey: "activeLimitId")
                        shared?.set(limit.limitMinutes, forKey: "activeLimitMinutes")
                        shared?.set(limit.isEnabled, forKey: "activeLimitEnabled")
                        // Store the selection data so extension can apply shield with correct tokens
                        shared?.set(limit.appSelectionData, forKey: "activeLimitSelectionData")
                        shared?.synchronize()
                    }
            }
            #endif
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    #if !targetEnvironment(simulator)
    private func filterForLimit(_ limit: UsageLimit) -> DeviceActivityFilter {
        let selection = limit.decodedSelection
        let interval = Calendar.current.dateInterval(of: .day, for: .now)
            ?? DateInterval(start: .now, duration: 86400)

        if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: selection.applicationTokens,
                categories: selection.categoryTokens
            )
        } else {
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad])
            )
        }
    }
    #endif

    // MARK: - Routines

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Routines")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)
                .padding(.leading, 4)
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

    private func routineIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("morning") { return "\u{1F305}" }
        if l.contains("work") || l.contains("focus") { return "\u{1F4BC}" }
        if l.contains("night") || l.contains("evening") || l.contains("wind") { return "\u{1F319}" }
        if l.contains("study") { return "\u{1F4DA}" }
        return "\u{1F6E1}\u{FE0F}"
    }

    private var addRoutineButton: some View {
        Button {
            editingRoutine = nil
            showEditor = true
        } label: {
            HStack { Image(systemName: "plus.circle.fill"); Text("Add Routine") }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(BrainRotTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func formatEndTime(_ r: BlockRoutine) -> String {
        let h = r.endHour % 12 == 0 ? 12 : r.endHour % 12
        let p = r.endHour < 12 ? "AM" : "PM"
        return r.endMinute == 0 ? "\(h) \(p)" : "\(h):\(String(format: "%02d", r.endMinute)) \(p)"
    }
}
