import SwiftUI

struct ScrollTypeView: View {
    let scrollType: ScrollType

    var body: some View {
        HStack(spacing: 14) {
            // Emoji
            Text(scrollType.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR SCROLL TYPE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(scrollType.color.opacity(0.8))
                    .tracking(2)

                Text(scrollType.title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)

                Text(scrollType.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BrainRotTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scrollType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
