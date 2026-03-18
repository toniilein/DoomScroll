import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
#endif

struct LimitEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var limitHours: Int
    @State private var limitMinutes: Int
    @State private var isEnabled: Bool
    @State private var limitId: UUID
    @State private var showAppPicker = false

    #if !targetEnvironment(simulator)
    @State private var appSelection: FamilyActivitySelection
    #endif

    let onSave: (UsageLimit) -> Void
    let onDelete: ((UsageLimit) -> Void)?

    private let isEditing: Bool

    init(limit: UsageLimit, onSave: @escaping (UsageLimit) -> Void, onDelete: ((UsageLimit) -> Void)?) {
        self.onSave = onSave
        self.onDelete = onDelete
        // If the name is empty, treat as "new"
        self.isEditing = !limit.name.isEmpty

        let l = limit

        _name = State(initialValue: l.name)
        _limitHours = State(initialValue: l.limitMinutes / 60)
        _limitMinutes = State(initialValue: l.limitMinutes % 60)
        _isEnabled = State(initialValue: l.isEnabled)
        _limitId = State(initialValue: l.id)

        #if !targetEnvironment(simulator)
        _appSelection = State(initialValue: l.decodedSelection)
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nameSection
                        timeLimitSection
                        appsSection

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

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apps to Limit")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 18))
                        .foregroundColor(BrainRotTheme.neonOrange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Apps")
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

    private var deleteButton: some View {
        Button {
            let limit = buildLimit()
            onDelete?(limit)
        } label: {
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
    }

    private func save() {
        onSave(buildLimit())
    }

    private func buildLimit() -> UsageLimit {
        var limit = UsageLimit(
            id: limitId,
            name: name.trimmingCharacters(in: .whitespaces),
            limitMinutes: limitHours * 60 + limitMinutes,
            isEnabled: isEnabled
        )

        #if !targetEnvironment(simulator)
        limit.decodedSelection = appSelection
        #endif

        return limit
    }
}
