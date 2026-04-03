import SwiftUI

struct WeekdayPickerView: View {
    @Binding var activeDays: Set<Int>

    // 1=Sun, 2=Mon, ..., 7=Sat (Calendar weekday numbering)
    private let days: [(id: Int, label: String)] = [
        (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S"), (1, "S")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Days")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(BrainRotTheme.textSecondary)

            HStack(spacing: 6) {
                ForEach(days, id: \.id) { day in
                    let isActive = activeDays.contains(day.id)

                    Button {
                        if isActive && activeDays.count > 1 {
                            activeDays.remove(day.id)
                        } else {
                            activeDays.insert(day.id)
                        }
                    } label: {
                        Text(day.label)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(isActive ? .white : BrainRotTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                isActive
                                    ? AnyShapeStyle(BrainRotTheme.accentGradient)
                                    : AnyShapeStyle(BrainRotTheme.cardBorder.opacity(0.5))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Quick select buttons
            HStack(spacing: 8) {
                quickButton("Weekdays", days: [2, 3, 4, 5, 6])
                quickButton("Weekends", days: [1, 7])
                quickButton("Every day", days: [1, 2, 3, 4, 5, 6, 7])
            }
        }
    }

    private func quickButton(_ label: String, days: [Int]) -> some View {
        let isSelected = activeDays == Set(days)

        return Button {
            activeDays = Set(days)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? BrainRotTheme.neonPink : BrainRotTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? BrainRotTheme.neonPink.opacity(0.12) : BrainRotTheme.cardBorder.opacity(0.3))
                .clipShape(Capsule())
        }
    }
}
