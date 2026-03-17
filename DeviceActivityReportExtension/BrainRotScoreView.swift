import SwiftUI

struct BrainRotScoreView: View {
    let score: Int
    let totalScreenTime: String
    var subtitle: String? = nil
    var compact: Bool = false

    @State private var animatedScore: Double = 0
    @State private var glowPulse = false

    private var ringSize: CGFloat { compact ? 160 : 200 }
    private var lineWidth: CGFloat { compact ? 14 : 18 }
    private var fontSize: CGFloat { compact ? 44 : 56 }

    var body: some View {
        VStack(spacing: compact ? 10 : 14) {
            ZStack {
                // Glow shadow behind ring
                Circle()
                    .fill(BrainRotTheme.scoreColor(for: score).opacity(0.15))
                    .frame(width: ringSize + 40, height: ringSize + 40)
                    .blur(radius: 20)
                    .scaleEffect(glowPulse ? 1.1 : 0.95)

                // Background ring
                Circle()
                    .stroke(BrainRotTheme.cardBorder, lineWidth: lineWidth)
                    .frame(width: ringSize, height: ringSize)

                // Score ring
                Circle()
                    .trim(from: 0, to: animatedScore / 100.0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                BrainRotTheme.neonGreen,
                                BrainRotTheme.neonBlue,
                                BrainRotTheme.neonPurple,
                                BrainRotTheme.neonPink
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: BrainRotTheme.scoreColor(for: score).opacity(0.6), radius: 8)

                // Score text
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: fontSize, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.scoreColor(for: score))

                    Text(totalScreenTime)
                        .font(.system(size: compact ? 12 : 14, weight: .medium))
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            }

            // Tier badge capsule
            HStack(spacing: 6) {
                Text(BrainRotTheme.scoreEmoji(for: score))
                    .font(.system(size: compact ? 14 : 16))
                Text(BrainRotTheme.scoreLabel(for: score))
                    .font(.system(size: compact ? 11 : 13, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(BrainRotTheme.tierBadgeColor(for: score).opacity(0.3))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(BrainRotTheme.tierBadgeColor(for: score).opacity(0.6), lineWidth: 1)
            )

            // Snarky one-liner
            if !compact {
                Text(BrainRotCalculator.snarkyOneLiner(for: score))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Optional subtitle (e.g., "Brain Remaining: 72%")
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption.bold())
                    .foregroundColor(BrainRotTheme.scoreColor(for: score).opacity(0.8))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = Double(score)
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedScore = Double(newValue)
            }
        }
    }
}
