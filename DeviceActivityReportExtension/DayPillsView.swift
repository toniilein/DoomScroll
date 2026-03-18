import SwiftUI

struct DayPillsView: View {
    let pillsData: DayPillsData

    @State private var selectedOffset: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(pillsData.days) { day in
                let isSelected = day.id == selectedOffset

                Button {
                    selectedOffset = day.id
                    // Write selected offset to shared UserDefaults so main app picks it up
                    let shared = UserDefaults(suiteName: "group.pookie1.shared")
                    shared?.set(day.id, forKey: "selectedDayOffset")
                    shared?.synchronize()
                } label: {
                    dayPillView(day: day, isSelected: isSelected)
                }
            }
        }
        .onAppear {
            // Read current selection from shared UserDefaults
            let shared = UserDefaults(suiteName: "group.pookie1.shared")
            selectedOffset = shared?.integer(forKey: "selectedDayOffset") ?? 0
        }
    }

    private func dayPillView(day: DayPillData, isSelected: Bool) -> some View {
        let mood = OctopusMood.from(score: day.score)
        let pillMood = day.hasData ? mood : OctopusMood.from(score: 0)

        return VStack(spacing: 2) {
            Text(day.dayLabel)
                .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : BrainRotTheme.textSecondary)

            // Mini octopus
            ZStack {
                Circle()
                    .fill(
                        day.hasData
                            ? AnyShapeStyle(
                                RadialGradient(
                                    colors: [pillMood.bodyColor, pillMood.bodyColorDark],
                                    center: .init(x: 0.4, y: 0.35),
                                    startRadius: 2, endRadius: 10
                                )
                            )
                            : AnyShapeStyle(BrainRotTheme.cardBorder.opacity(0.5))
                    )
                    .frame(width: 24, height: 24)

                if day.hasData {
                    // Tiny eyes
                    HStack(spacing: 6) {
                        Circle().fill(Color.white).frame(width: 4.5, height: 4.5)
                        Circle().fill(Color.white).frame(width: 4.5, height: 4.5)
                    }
                    .offset(y: -1)
                }
            }

            Text(day.dayNumber)
                .font(.system(size: 10, weight: isSelected ? .black : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : BrainRotTheme.textSecondary)

            if day.hasData {
                Text(day.formattedDuration)
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : BrainRotTheme.textSecondary.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: 48)
        .padding(.vertical, 6)
        .background(
            day.hasData
                ? (isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [pillMood.bodyColor, pillMood.bodyColorDark],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [pillMood.bodyColor.opacity(0.35), pillMood.bodyColorDark.opacity(0.2)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                )
                : (isSelected
                    ? AnyShapeStyle(BrainRotTheme.accentGradient)
                    : AnyShapeStyle(BrainRotTheme.cardBackground)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected && day.hasData ? pillMood.bodyColorDark.opacity(0.6) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}
