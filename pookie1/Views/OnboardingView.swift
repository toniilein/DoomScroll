import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var wavePhase: CGFloat = 0
    @State private var bodyBob: CGFloat = 0
    @State private var glowPulse = false
    @State private var particleDrift: CGFloat = 0
    @State private var particleFade: Double = 1

    // Ecstatic octopus colors
    private let bodyColor = Color(red: 0.55, green: 0.88, blue: 0.70)
    private let bodyColorDark = Color(red: 0.40, green: 0.75, blue: 0.55)

    var body: some View {
        ZStack {
            BrainRotTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Floating particles
                ZStack {
                    Circle()
                        .fill(bodyColor.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                        .scaleEffect(glowPulse ? 1.1 : 0.92)

                    // Particles
                    Text("\u{2728}")
                        .font(.system(size: 20))
                        .offset(x: -65, y: -60 + particleDrift * 0.7)
                        .opacity(particleFade)
                    Text("\u{1F496}")
                        .font(.system(size: 16))
                        .offset(x: 70, y: -40 + particleDrift)
                        .opacity(particleFade * 0.7)
                    Text("\u{2728}")
                        .font(.system(size: 14))
                        .offset(x: 55, y: -75 + particleDrift * 0.5)
                        .opacity(particleFade * 0.5)

                    VStack(spacing: -10) {
                        // Octopus body
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [bodyColor, bodyColorDark],
                                        center: .init(x: 0.4, y: 0.35),
                                        startRadius: 10,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .shadow(color: bodyColor.opacity(0.35), radius: 12, y: 6)

                            // Spots
                            Circle()
                                .fill(Color(red: 0.45, green: 0.78, blue: 0.58).opacity(0.4))
                                .frame(width: 12, height: 12)
                                .offset(x: -35, y: -20)
                            Circle()
                                .fill(Color(red: 0.45, green: 0.78, blue: 0.58).opacity(0.3))
                                .frame(width: 8, height: 8)
                                .offset(x: 38, y: -30)
                            Circle()
                                .fill(Color(red: 0.45, green: 0.78, blue: 0.58).opacity(0.35))
                                .frame(width: 10, height: 10)
                                .offset(x: 42, y: 5)

                            // Shine
                            Ellipse()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.50), Color.clear],
                                        center: .init(x: 0.4, y: 0.3),
                                        startRadius: 0,
                                        endRadius: 45
                                    )
                                )
                                .frame(width: 100, height: 80)
                                .offset(x: -12, y: -22)

                            Ellipse()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 16, height: 10)
                                .rotationEffect(.degrees(-25))
                                .offset(x: -32, y: -38)

                            // Face
                            VStack(spacing: 4) {
                                // Star eyes (ecstatic)
                                HStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 36, height: 36)
                                            .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                                        Text("\u{2605}")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(bodyColorDark)
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 6, y: -6)
                                    }
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 36, height: 36)
                                            .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                                        Text("\u{2605}")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(bodyColorDark)
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 6, y: -6)
                                    }
                                }

                                // Cheeks
                                HStack(spacing: 50) {
                                    Ellipse()
                                        .fill(Color.pink.opacity(0.45))
                                        .frame(width: 20, height: 12)
                                    Ellipse()
                                        .fill(Color.pink.opacity(0.45))
                                        .frame(width: 20, height: 12)
                                }
                                .offset(y: -2)

                                // Happy mouth
                                ZStack {
                                    Path { p in
                                        p.move(to: CGPoint(x: 0, y: 0))
                                        p.addQuadCurve(to: CGPoint(x: 28, y: 0), control: CGPoint(x: 14, y: 20))
                                        p.closeSubpath()
                                    }
                                    .fill(Color(red: 0.92, green: 0.50, blue: 0.55).opacity(0.5))
                                    .frame(width: 28, height: 20)

                                    Path { p in
                                        p.move(to: CGPoint(x: 0, y: 0))
                                        p.addQuadCurve(to: CGPoint(x: 28, y: 0), control: CGPoint(x: 14, y: 20))
                                    }
                                    .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: 28, height: 20)
                                }
                            }
                            .offset(y: 8)
                        }

                        // Tentacles
                        OnboardingTentaclesShape(phase: wavePhase, amplitude: 10, droop: 0)
                            .stroke(
                                LinearGradient(
                                    colors: [bodyColorDark, bodyColorDark.opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 140, height: 40)
                    }
                    .offset(y: bodyBob)
                }
                .frame(height: 240)

                Spacer().frame(height: 24)

                // App name
                Text("ScreenRot")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)

                Spacer().frame(height: 8)

                Text("your screen time guardian")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Spacer()

                // Bottom section
                VStack(spacing: 20) {
                    // Feature pills
                    HStack(spacing: 10) {
                        featurePill(icon: "chart.bar.fill", text: "Track Usage")
                        featurePill(icon: "shield.fill", text: "Block Apps")
                        featurePill(icon: "brain.fill", text: "Brain Health")
                    }

                    Text("We need Screen Time access to help you take control of your screen habits")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(BrainRotTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        Task {
                            await screenTimeManager.requestAuthorization()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [bodyColor, bodyColorDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: bodyColorDark.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 32)

                    if screenTimeManager.authorizationStatus == .denied {
                        VStack(spacing: 8) {
                            Text("Authorization denied.")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.neonPink)

                            if let error = screenTimeManager.authError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(BrainRotTheme.textSecondary)
                            }

                            Text("Make sure Screen Time is enabled in Settings > Screen Time")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(BrainRotTheme.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    }
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Feature Pill

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(bodyColorDark)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(bodyColor.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(
            .linear(duration: 1.2)
            .repeatForever(autoreverses: false)
        ) {
            wavePhase = 1.0
        }

        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            bodyBob = 8
        }

        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = true
        }

        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            particleDrift = -15
            particleFade = 0.3
        }
    }
}

// MARK: - Tentacles Shape (standalone for onboarding, avoids extension dependency)

struct OnboardingTentaclesShape: Shape {
    var phase: CGFloat
    let amplitude: CGFloat
    let droop: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = 6
        let spacing = rect.width / CGFloat(count + 1)

        for i in 0..<count {
            let startX = spacing * CGFloat(i + 1)
            let length: CGFloat = rect.height
            let offset = CGFloat(i) * .pi / 3.0
            let segments = 4

            path.move(to: CGPoint(x: startX, y: 0))

            for seg in 1...segments {
                let t1 = CGFloat(seg) / CGFloat(segments)
                let tMid = (CGFloat(seg) - 0.5) / CGFloat(segments)

                let wave = { (t: CGFloat) -> CGFloat in
                    sin(t * .pi * 2 + self.phase * .pi * 2 + offset) * self.amplitude * t
                }

                let cpX = startX + wave(tMid)
                let cpY = tMid * length
                let endX = startX + wave(t1)
                let endY = t1 * length

                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: cpX, y: cpY)
                )
            }
        }
        return path
    }
}
