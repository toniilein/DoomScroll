import SwiftUI
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
                        appsSection
                        timeLimitSection
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
            .navigationTitle(isEditing ? "Edit Limit" : "New Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(canSave ? BrainRotTheme.neonPink : BrainRotTheme.textSecondary)
                        .disabled(!canSave)
                }
            }
            #if !targetEnvironment(simulator)
            .familyActivityPicker(
                isPresented: $showAppPicker,
                selection: $appSelection
            )
            #endif
        }
    }

    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let hasTime = (limitHours * 60 + limitMinutes) > 0
        #if !targetEnvironment(simulator)
        let hasApps = !appSelection.applicationTokens.isEmpty || !appSelection.categoryTokens.isEmpty
        return hasName && hasTime && hasApps
        #else
        return hasName && hasTime
        #endif
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            TextField("Social Media", text: $name)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Apps to Limit

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apps to Limit")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            Button { showAppPicker = true } label: {
                HStack {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 18))
                        .foregroundColor(BrainRotTheme.neonOrange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Apps & Categories")
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
                            Text("Tap to choose apps and categories")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                        #else
                        Text("Not available in simulator")
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
            Text("Daily Limit")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Picker("Hours", selection: $limitHours) {
                        ForEach(0..<13) { h in
                            Text("\(h)h").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()

                    Text("Hours")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }

                VStack(spacing: 4) {
                    Picker("Minutes", selection: $limitMinutes) {
                        ForEach([0, 5, 10, 15, 20, 30, 45], id: \.self) { m in
                            Text("\(m)m").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()

                    Text("Minutes")
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

    // MARK: - Today's Usage — native cards, data from catMin_ keys (written by Overview tab)

    private var todayUsageSection: some View {
        let categories = loadCategoryUsage()
        let totalMinutes = categories.reduce(0.0) { $0 + $1.minutes }
        let limitMins = Double(limitHours * 60 + limitMinutes)
        let exceeded = limitMins > 0 && totalMinutes >= limitMins
        let progress = limitMins > 0 ? min(1.0, totalMinutes / limitMins) : 0

        return VStack(alignment: .leading, spacing: 10) {
            Text("Today's Usage")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            // Total summary card
            VStack(spacing: 6) {
                HStack {
                    Text(formatMinutes(totalMinutes))
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
                            Text("Exceeded")
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

            // Per-category cards
            if categories.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 16))
                        .foregroundColor(BrainRotTheme.textSecondary.opacity(0.4))
                    Text("Usage data loads from Overview tab")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(categories, id: \.name) { cat in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(BrainRotTheme.neonOrange.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: categoryIcon(cat.name))
                                    .font(.system(size: 15))
                                    .foregroundColor(BrainRotTheme.neonOrange)
                            )

                        Text(cat.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(formatMinutes(cat.minutes))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BrainRotTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Read category data

    private struct CategoryUsage {
        let name: String
        let minutes: Double
    }

    private func loadCategoryUsage() -> [CategoryUsage] {
        // Primary: read from categoryUsage.json file (written by LimitUsageReport extension)
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.pookie1.shared"
        )?.appendingPathComponent("categoryUsage.json"),
           let data = try? Data(contentsOf: url),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
            let results = dict.filter { $0.value > 0 }
                .map { CategoryUsage(name: $0.key, minutes: $0.value) } // file stores minutes
                .sorted { $0.minutes > $1.minutes }
            if !results.isEmpty { return results }
        }

        // Fallback: read from UserDefaults catMin_ keys (written by TotalActivityReport)
        let shared = UserDefaults(suiteName: "group.pookie1.shared")
        shared?.synchronize()

        var names: [String] = []
        if let namesStr = shared?.string(forKey: "todayCategoryNamesStr"), !namesStr.isEmpty {
            names = namesStr.components(separatedBy: "|||").filter { !$0.isEmpty }
        }
        if names.isEmpty, let arr = shared?.stringArray(forKey: "todayCategoryNames") {
            names = arr
        }

        var results: [CategoryUsage] = []
        for catName in names {
            let mins = shared?.double(forKey: "catMin_\(catName)") ?? 0
            if mins > 0 {
                results.append(CategoryUsage(name: catName, minutes: mins))
            }
        }
        return results.sorted { $0.minutes > $1.minutes }
    }

    private func categoryIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("social") { return "person.2.fill" }
        if l.contains("entertainment") { return "play.tv.fill" }
        if l.contains("game") { return "gamecontroller.fill" }
        if l.contains("product") { return "briefcase.fill" }
        if l.contains("utilit") { return "wrench.fill" }
        if l.contains("info") || l.contains("read") { return "newspaper.fill" }
        if l.contains("shop") || l.contains("food") { return "cart.fill" }
        if l.contains("health") || l.contains("fitness") { return "heart.fill" }
        if l.contains("travel") { return "car.fill" }
        if l.contains("creat") { return "paintbrush.fill" }
        if l.contains("music") || l.contains("audio") { return "music.note" }
        if l.contains("photo") || l.contains("video") { return "camera.fill" }
        if l.contains("education") || l.contains("reference") { return "book.fill" }
        if l.contains("news") { return "newspaper.fill" }
        return "app.fill"
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
                Text("Delete Limit")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .alert("Delete \"\(name)\"?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?(buildLimit())
            }
        } message: {
            Text("This limit and its settings will be permanently removed.")
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
