import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
#endif

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isEnabled: Bool
    @State private var routineId: UUID
    @State private var createdAt: Date
    @State private var showAppPicker = false

    #if !targetEnvironment(simulator)
    @State private var appSelection: FamilyActivitySelection
    #endif

    let onSave: (BlockRoutine) -> Void
    let onDelete: ((BlockRoutine) -> Void)?

    private let isEditing: Bool

    init(routine: BlockRoutine?, onSave: @escaping (BlockRoutine) -> Void, onDelete: ((BlockRoutine) -> Void)?) {
        self.onSave = onSave
        self.onDelete = onDelete
        self.isEditing = routine != nil

        let r = routine ?? BlockRoutine(
            name: "",
            startHour: 21,
            startMinute: 0,
            endHour: 7,
            endMinute: 0
        )

        _name = State(initialValue: r.name)
        _isEnabled = State(initialValue: r.isEnabled)
        _routineId = State(initialValue: r.id)
        _createdAt = State(initialValue: r.createdAt)

        var startComponents = DateComponents()
        startComponents.hour = r.startHour
        startComponents.minute = r.startMinute
        _startTime = State(initialValue: Calendar.current.date(from: startComponents) ?? Date())

        var endComponents = DateComponents()
        endComponents.hour = r.endHour
        endComponents.minute = r.endMinute
        _endTime = State(initialValue: Calendar.current.date(from: endComponents) ?? Date())

        #if !targetEnvironment(simulator)
        _appSelection = State(initialValue: r.decodedSelection)
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Name
                        nameSection

                        // Time
                        timeSection

                        // Apps
                        appsSection

                        // Delete
                        if isEditing {
                            deleteButton
                                .padding(.top, 12)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
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
        #if !targetEnvironment(simulator)
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (!appSelection.applicationTokens.isEmpty || !appSelection.categoryTokens.isEmpty)
        #else
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
        #endif
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            TextField("Evening Routine", text: $name)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(BrainRotTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            VStack(spacing: 0) {
                HStack {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Spacer()
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(BrainRotTheme.neonPink)
                }
                .padding(14)

                Divider().padding(.leading, 14)

                HStack {
                    Label("End", systemImage: "stop.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrainRotTheme.textPrimary)
                    Spacer()
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(BrainRotTheme.neonPink)
                }
                .padding(14)
            }
            .background(BrainRotTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Overnight indicator
            let startH = Calendar.current.component(.hour, from: startTime)
            let endH = Calendar.current.component(.hour, from: endTime)
            if startH > endH || (startH == endH && Calendar.current.component(.minute, from: startTime) > Calendar.current.component(.minute, from: endTime)) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                    Text("Overnight schedule")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(BrainRotTheme.neonPurple)
                .padding(.leading, 4)
            }
        }
    }

    // MARK: - Apps Section

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apps to Block")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 18))
                        .foregroundColor(BrainRotTheme.neonPink)

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

    // MARK: - Delete

    private var deleteButton: some View {
        Button {
            let routine = buildRoutine()
            onDelete?(routine)
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Routine")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Save

    private func save() {
        let routine = buildRoutine()
        onSave(routine)
    }

    private func buildRoutine() -> BlockRoutine {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)

        var routine = BlockRoutine(
            id: routineId,
            name: name.trimmingCharacters(in: .whitespaces),
            startHour: startComponents.hour ?? 21,
            startMinute: startComponents.minute ?? 0,
            endHour: endComponents.hour ?? 7,
            endMinute: endComponents.minute ?? 0,
            isEnabled: isEnabled,
            createdAt: createdAt
        )

        #if !targetEnvironment(simulator)
        routine.decodedSelection = appSelection
        #endif

        return routine
    }
}
