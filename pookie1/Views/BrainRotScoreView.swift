import SwiftUI

struct BrainRotScoreView: View {
    let score: Int
    let totalScreenTime: String
    @State private var animatedScore: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 16)
                    .frame(width: 180, height: 180)

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
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(BrainRotTheme.scoreColor(for: score))
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(BrainRotTheme.textSecondary)
                }
            }

            Text(BrainRotTheme.scoreLabel(for: score))
                .font(.headline)
                .foregroundColor(BrainRotTheme.scoreColor(for: score))

            Text(totalScreenTime)
                .font(.subheadline)
                .foregroundColor(BrainRotTheme.textSecondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = Double(score)
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedScore = Double(newValue)
            }
        }
    }
}
