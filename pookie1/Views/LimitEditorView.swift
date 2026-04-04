import SwiftUI
import Combine
#if !targetEnvironment(simulator)
import FamilyControls
import DeviceActivity
#endif

struct LimitEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var limitHours: Int
    @State private var limitMinutes: Int
    @State private var isEnabled: Bool
    @State private var limitId: UUID
    @State private var activeDays: Set<Int>
    @State private var showAppPicker = false
    @State private var showDeleteConfirm = false
    @State private var showValidation = false
    @State private var currentUsageMinutes: Double = 0
    private let usageTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    #if !targetEnvironment(simulator)
    @State private var appSelection: FamilyActivitySelection
    #endif

    let onSave: (UsageLimit) -> Void
    let onDelete: ((UsageLimit) -> Void)?

    private let isEditing: Bool

    init(limit: UsageLimit, onSave: @escaping (UsageLimit) -> Void, onDelete: ((UsageLimit) -> Void)?) {
        self.onSave = onSave
        self.onDelete = onDelete
        self.isEditing = !limit.name.isEmpty

        _name = State(initialValue: limit.name)
        _limitHours = State(initialValue: limit.limitMinutes / 60)
        _limitMinutes = State(initialValue: limit.limitMinutes % 60)
        _isEnabled = State(initialValue: limit.isEnabled)
        _limitId = State(initialValue: limit.id)
        _activeDays = State(initialValue: limit.activeDays)

        #if !targetEnvironment(simulator)
        _appSelection = State(initialValue: limit.decodedSelection)
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nameSection
                        if showValidation && !hasName {
                            validationWarning(L("validation.nameRequired"))
                        }
                        appsSection
                        #if !targetEnvironment(simulator)
                        if showValidation && !hasApps {
                            validationWarning(L("validation.appsRequired"))
                        }
                        #endif
                        timeLimitSection
                        if showValidation && !hasTime {
                            validationWarning(L("validation.timeRequired"))
                        }
                        WeekdayPickerView(activeDays: $activeDays)
                        todayUsageSection

                        if isEditing {
                            deleteButton.padding(.top, 12)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? L("limitEditor.editTitle") : L("limitEditor.newTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("limitEditor.cancel")) { dismiss() }
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("limitEditor.save")) {
                        if canSave {
                            save()
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) { showValidation = true }
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(canSave ? BrainRotTheme.neonPink : BrainRotTheme.textSecondary)
                }
            }
            #if !targetEnvironment(simulator)
            .familyActivityPicker(
                isPresented: $showAppPicker,
                selection: $appSelection
            )
            #endif
            .onAppear { currentUsageMinutes = loadLimitUsage() }
            .onReceive(usageTimer) { _ in currentUsageMinutes = loadLimitUsage() }
        }
    }

    private var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var hasTime: Bool { (limitHours * 60 + limitMinutes) > 0 }
    #if !targetEnvironment(simulator)
    private var hasApps: Bool { !appSelection.applicationTokens.isEmpty || !appSelection.categoryTokens.isEmpty }
    private var canSave: Bool { hasName && hasTime && hasApps }
    #else
    private var canSave: Bool { hasName && hasTime }
    #endif

    private func validationWarning(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -12)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("limitEditor.name"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            TextField(L("limitEditor.namePlaceholder"), text: $name)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Apps to Limit

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("limitEditor.appsToLimit"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            Button { showAppPicker = true } label: {
                HStack {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 18))
                        .foregroundColor(BrainRotTheme.neonOrange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("limitEditor.selectApps"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)

                        #if !targetEnvironment(simulator)
                        let apps = appSelection.applicationTokens.count
                        let cats = appSelection.categoryTokens.count
                        if apps > 0 || cats > 0 {
                            Text("\(apps) app\(apps == 1 ? "" : "s"), \(cats) categor\(cats == 1 ? "y" : "ies")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        } else {
                            Text(L("limitEditor.tapToChoose"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                        #else
                        Text(L("common.notAvailableSimulator"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BrainRotTheme.textSecondary)
                        #endif
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                .padding(14)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Daily Limit

    private var timeLimitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("limitEditor.dailyLimit"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Picker(L("limitEditor.hours"), selection: $limitHours) {
                        ForEach(0..<13) { h in
                            Text("\(h)h").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()

                    Text(L("limitEditor.hours"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }

                VStack(spacing: 4) {
                    Picker(L("limitEditor.minutes"), selection: $limitMinutes) {
                        ForEach([0, 5, 10, 15, 20, 30, 45], id: \.self) { m in
                            Text("\(m)m").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()

                    Text(L("limitEditor.minutes"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Today's Usage — reads from limitProgress_{id} written by LimitUsageReport extension

    private var todayUsageSection: some View {
        let usedMinutes = currentUsageMinutes
        let limitMins = Double(limitHours * 60 + limitMinutes)
        let exceeded = limitMins > 0 && usedMinutes >= limitMins
        let progress = limitMins > 0 ? min(1.0, usedMinutes / limitMins) : 0

        return VStack(alignment: .leading, spacing: 10) {
            Text(L("limitEditor.todayUsage"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            // Total summary card
            VStack(spacing: 6) {
                HStack {
                    Text(formatMinutes(usedMinutes))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(exceeded ? .red : BrainRotTheme.neonOrange)

                    Text("/ \(formatLimit())")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)

                    Spacer()

                    if exceeded {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(L("limitEditor.exceeded"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.red)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(BrainRotTheme.cardBorder)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(exceeded ? Color.red : BrainRotTheme.neonOrange)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 5)
            }
            .padding(14)
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Read limit-specific usage

    /// Reads usage for this specific limit from shared UserDefaults + file fallback.
    /// Written by LimitUsageReport extension and DeviceActivityMonitor as limitProgress_{limitId}
    private func loadLimitUsage() -> Double {
        let idStr = limitId.uuidString
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.synchronize()

        // Try UserDefaults first (written by monitor extension + report extension)
        let fromDefaults = shared?.integer(forKey: "limitProgress_\(idStr)") ?? 0

        // Also try file-based usage data (more reliable cross-process)
        var fromFile = 0
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.pookie1.shared"
        )?.appendingPathComponent("limitUsage.json"),
           let data = try? Data(contentsOf: url),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            fromFile = dict[idStr] ?? 0
        }

        // Return whichever is higher (both sources may have data)
        return Double(max(fromDefaults, fromFile))
    }

    private func formatMinutes(_ mins: Double) -> String {
        let totalMins = Int(mins)
        let h = totalMins / 60, m = totalMins % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func formatLimit() -> String {
        let total = limitHours * 60 + limitMinutes
        let h = total / 60, m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        if m > 0 { return "\(m)m" }
        return "0m"
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack {
                Image(systemName: "trash")
                Text(L("limitEditor.deleteLimit"))
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .alert(String(format: L("limitEditor.deleteTitle"), name), isPresented: $showDeleteConfirm) {
            Button(L("common.cancel"), role: .cancel) {}
            Button(L("common.delete"), role: .destructive) {
                onDelete?(buildLimit())
            }
        } message: {
            Text(L("limitEditor.deleteMessage"))
        }
    }

    // MARK: - Save

    private func save() {
        onSave(buildLimit())
    }

    private func buildLimit() -> UsageLimit {
        var limit = UsageLimit(
            id: limitId,
            name: name.trimmingCharacters(in: .whitespaces),
            limitMinutes: limitHours * 60 + limitMinutes,
            isEnabled: isEnabled,
            activeDays: activeDays
        )

        #if !targetEnvironment(simulator)
        limit.decodedSelection = appSelection
        #endif

        return limit
    }
}
