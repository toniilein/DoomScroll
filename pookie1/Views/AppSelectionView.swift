import SwiftUI
#if !targetEnvironment(simulator)
import FamilyControls
#endif

struct AppSelectionView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrainRotTheme.background.ignoresSafeArea()

                if !screenTimeManager.isAuthorized {
                    VStack(spacing: 16) {
                        Text("\u{1F4F1}")
                            .font(.system(size: 60))
                        Text("Screen Time Required")
                            .font(.title2.bold())
                            .foregroundColor(BrainRotTheme.textPrimary)
                        Text("Enable Screen Time on the Overview tab to select apps to track")
                            .font(.body)
                            .foregroundColor(BrainRotTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("\u{1F4F1} Tracked Apps")
                                .font(.title2.bold())
                                .foregroundColor(BrainRotTheme.textPrimary)

                            Text(screenTimeManager.hasSelectedApps
                                ? "Tracking selected apps"
                                : "Tracking all apps \u{2014} select specific ones to filter")
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
            }
            .navigationTitle("Apps")
            #if !targetEnvironment(simulator)
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $screenTimeManager.activitySelection
            )
            .onChange(of: screenTimeManager.activitySelection) { _, _ in
                screenTimeManager.saveSelection()
            }
            #endif
        }
    }

    private var selectionSummaryCard: some View {
        HStack {
            #if !targetEnvironment(simulator)
            summaryItem(label: "Apps", count: screenTimeManager.activitySelection.applicationTokens.count, color: BrainRotTheme.neonGreen)
            Spacer()
            summaryItem(label: "Categories", count: screenTimeManager.activitySelection.categoryTokens.count, color: BrainRotTheme.neonBlue)
            Spacer()
            summaryItem(label: "Websites", count: screenTimeManager.activitySelection.webDomainTokens.count, color: BrainRotTheme.neonPurple)
            #else
            summaryItem(label: "Apps", count: 0, color: BrainRotTheme.neonGreen)
            Spacer()
            summaryItem(label: "Categories", count: 0, color: BrainRotTheme.neonBlue)
            Spacer()
            summaryItem(label: "Websites", count: 0, color: BrainRotTheme.neonPurple)
            #endif
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
