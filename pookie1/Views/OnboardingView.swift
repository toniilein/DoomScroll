import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            BrainRotTheme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("\u{1F9E0}")
                    .font(.system(size: 80))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                VStack(spacing: 12) {
                    Text("DoomScroll")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(BrainRotTheme.accentGradient)

                    Text("know your brain health")
                        .font(.title3)
                        .foregroundColor(BrainRotTheme.textSecondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("We need Screen Time access to track your doomscrolling and protect your brain health")
                        .font(.body)
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button {
                        Task {
                            await screenTimeManager.requestAuthorization()
                        }
                    } label: {
                        Text("Let's Go")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BrainRotTheme.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)

                    if screenTimeManager.authorizationStatus == .denied {
                        VStack(spacing: 8) {
                            Text("Authorization denied.")
                                .font(.caption.bold())
                                .foregroundColor(BrainRotTheme.neonPink)

                            if let error = screenTimeManager.authError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(BrainRotTheme.textSecondary)
                            }

                            Text("Make sure Screen Time is enabled in Settings > Screen Time")
                                .font(.caption)
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    }
                }

                Spacer()
            }
        }
        .onAppear { isAnimating = true }
    }
}
