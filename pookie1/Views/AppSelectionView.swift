import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("\u{1F4F1} Tracked Apps")
                            .font(.title2.bold())
                            .foregroundColor(BrainRotTheme.textPrimary)

                        Text("Select the apps contributing to your brainrot")
                            .font(.subheadline)
                            .foregroundColor(BrainRotTheme.textSecondary)
                    }
                    .padding(.top, 20)

                    selectionSummaryCard

                    Button {
                        isPickerPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.app")
                            Text(screenTimeManager.hasSelectedApps ? "Change Apps" : "Select Apps")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrainRotTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Apps")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $screenTimeManager.activitySelection
            )
            .onChange(of: screenTimeManager.activitySelection) { _, _ in
                screenTimeManager.saveSelection()
            }
        }
    }

    private var selectionSummaryCard: some View {
        HStack {
            summaryItem(
                label: "Apps",
                count: screenTimeManager.activitySelection.applicationTokens.count,
                color: BrainRotTheme.neonGreen
            )
            Spacer()
            summaryItem(
                label: "Categories",
                count: screenTimeManager.activitySelection.categoryTokens.count,
                color: BrainRotTheme.neonBlue
            )
            Spacer()
            summaryItem(
                label: "Websites",
                count: screenTimeManager.activitySelection.webDomainTokens.count,
                color: BrainRotTheme.neonPurple
            )
        }
        .padding()
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(BrainRotTheme.neonPurple.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func summaryItem(label: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(BrainRotTheme.textSecondary)
            Text("\(count)")
                .font(.title.bold())
                .foregroundColor(color)
        }
    }
}
