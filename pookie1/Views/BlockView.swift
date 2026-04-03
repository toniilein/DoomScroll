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
    @State private var showUnblockConfirm = false

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

                        todayUsageSection

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
        let now = Calendar.current.dateComponents([.hour, .minute, .weekday], from: Date())
        let cur = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let weekday = now.weekday ?? 1 // 1=Sun..7=Sat
        return blockingManager.routines.filter { r in
            guard r.isEnabled else { return false }
            guard r.activeDays.contains(weekday) else { return false }
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

    // MARK: - Today's Usage (reads from UserDefaults written by TotalActivityReport)

    private var todayUsageSection: some View {
        let shared = SharedSettings.sharedDefaults
        let totalMinutes = shared.double(forKey: "lastScreenTimeMinutes")
        let catNamesStr = shared.string(forKey: "todayCategoryNamesStr") ?? ""
        let catNames = catNamesStr.isEmpty ? [] : catNamesStr.components(separatedBy: "|||")

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundColor(BrainRotTheme.neonOrange)
                Text("Today's Usage")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                Spacer()
                Text(formatDuration(totalMinutes * 60))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }

            if catNames.isEmpty {
                Text("Visit Overview tab to load usage data")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary.opacity(0.6))
            } else {
                ForEach(catNames.prefix(8), id: \.self) { catName in
                    let catMinutes = shared.double(forKey: "catMin_\(catName)")
                    if catMinutes > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: categoryIcon(catName))
                                .font(.system(size: 11))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .frame(width: 16)
                            Text(catName)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text(formatDuration(catMinutes * 60))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

            ForEach(blockingManager.usageLimits) { limit in
                limitCard(limit)
            }

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
            }
        }
    }

    private func limitCard(_ limit: UsageLimit) -> some View {
        let shared = SharedSettings.sharedDefaults
        let usedSeconds = shared.double(forKey: "limitUsage_\(limit.id.uuidString)")
        let usedMinutes = usedSeconds / 60.0
        let exceeded = usedMinutes >= Double(limit.limitMinutes)
        let progress = limit.limitMinutes > 0 ? min(1.0, usedMinutes / Double(limit.limitMinutes)) : 0

        return Button { editingLimit = limit } label: {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(limit.isEnabled ? BrainRotTheme.neonOrange.opacity(0.15) : BrainRotTheme.cardBorder)
                            .frame(width: 42, height: 42)
                        Image(systemName: limitIcon(limit.name))
                            .font(.system(size: 18))
                            .foregroundColor(limit.isEnabled ? BrainRotTheme.neonOrange : BrainRotTheme.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(limit.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                        HStack(spacing: 4) {
                            Text(formatDuration(usedSeconds))
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)
                            Text("/ \(limit.formattedLimit)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                            if exceeded {
                                HStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 8))
                                    Text("Exceeded")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.red)
                            }
                            Spacer()
                            Text(weekdaySummary(limit.activeDays))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(BrainRotTheme.textSecondary)
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
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(BrainRotTheme.cardBorder)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(exceeded ? Color.red : BrainRotTheme.neonOrange)
                            .frame(width: geo.size.width * progress)
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

    /// Writes usageLimits.json to app group container so the extension can read configs.
    /// Uses file I/O (not UserDefaults) because Data/arrays are unreliable cross-process.
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

    private func formatDuration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func categoryIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("social") { return "person.2.fill" }
        if l.contains("game") { return "gamecontroller.fill" }
        if l.contains("entertainment") { return "play.tv.fill" }
        if l.contains("productiv") { return "briefcase.fill" }
        if l.contains("education") { return "book.fill" }
        if l.contains("health") { return "heart.fill" }
        if l.contains("news") || l.contains("read") { return "newspaper.fill" }
        if l.contains("shopping") { return "cart.fill" }
        if l.contains("music") { return "music.note" }
        if l.contains("photo") || l.contains("video") { return "camera.fill" }
        if l.contains("utilit") { return "wrench.fill" }
        if l.contains("information") || l.contains("reference") { return "info.circle.fill" }
        return "app.fill"
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
                        .frame(width: 42, height: 42)
                    Text(icon).font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(routine.name).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(BrainRotTheme.textPrimary)
                    HStack(spacing: 8) {
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
