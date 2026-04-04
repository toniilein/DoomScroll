import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var screenTimeManager: ScreenTimeManager
    @State private var wavePhase: CGFloat = 0
    @State private var bodyBob: CGFloat = 0
    @State private var glowPulse = false
    @State private var particleDrift: CGFloat = 0
    @State private var particleFade: Double = 1
    @State private var showZombie = false
    @State private var moodCycleTimer: Timer?

    // Ecstatic octopus colors (green)
    private let bodyColor = Color(red: 0.55, green: 0.88, blue: 0.70)
    private let bodyColorDark = Color(red: 0.40, green: 0.75, blue: 0.55)

    // Zombie octopus colors (grey)
    private let zombieColor = Color(red: 0.68, green: 0.65, blue: 0.63)
    private let zombieColorDark = Color(red: 0.52, green: 0.50, blue: 0.48)

    private var currentBodyColor: Color { showZombie ? zombieColor : bodyColor }
    private var currentBodyColorDark: Color { showZombie ? zombieColorDark : bodyColorDark }

    var body: some View {
        ZStack {
            BrainRotTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Floating particles
                ZStack {
                    Circle()
                        .fill(currentBodyColor.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                        .scaleEffect(glowPulse ? 1.1 : 0.92)

                    // Particles
                    let particles: [String] = showZombie ? ["\u{1F480}", "\u{2620}\u{FE0F}", "\u{1F480}"] : ["\u{2728}", "\u{1F496}", "\u{2728}"]
                    Text(particles[0])
                        .font(.system(size: 20))
                        .offset(x: -65, y: -60 + particleDrift * 0.7)
                        .opacity(particleFade)
                    Text(particles[1])
                        .font(.system(size: 16))
                        .offset(x: 70, y: -40 + particleDrift)
                        .opacity(particleFade * 0.7)
                    Text(particles[2])
                        .font(.system(size: 14))
                        .offset(x: 55, y: -75 + particleDrift * 0.5)
                        .opacity(particleFade * 0.5)

                    VStack(spacing: -10) {
                        // Octopus body
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [currentBodyColor, currentBodyColorDark],
                                        center: .init(x: 0.4, y: 0.35),
                                        startRadius: 10,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .shadow(color: currentBodyColor.opacity(0.35), radius: 12, y: 6)

                            // Spots
                            let spotColor = showZombie ? zombieColorDark.opacity(0.3) : Color(red: 0.45, green: 0.78, blue: 0.58).opacity(0.4)
                            Circle()
                                .fill(spotColor)
                                .frame(width: 12, height: 12)
                                .offset(x: -35, y: -20)
                            Circle()
                                .fill(spotColor.opacity(0.75))
                                .frame(width: 8, height: 8)
                                .offset(x: 38, y: -30)
                            Circle()
                                .fill(spotColor.opacity(0.85))
                                .frame(width: 10, height: 10)
                                .offset(x: 42, y: 5)

                            // Shine
                            Ellipse()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(showZombie ? 0.30 : 0.50), Color.clear],
                                        center: .init(x: 0.4, y: 0.3),
                                        startRadius: 0,
                                        endRadius: 45
                                    )
                                )
                                .frame(width: 100, height: 80)
                                .offset(x: -12, y: -22)

                            Ellipse()
                                .fill(Color.white.opacity(showZombie ? 0.15 : 0.25))
                                .frame(width: 16, height: 10)
                                .rotationEffect(.degrees(-25))
                                .offset(x: -32, y: -38)

                            // Face — switches between ecstatic and zombie
                            if showZombie {
                                zombieFace
                            } else {
                                ecstaticFace
                            }
                        }

                        // Tentacles
                        OnboardingTentaclesShape(phase: wavePhase, amplitude: showZombie ? 1 : 10, droop: showZombie ? 20 : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [currentBodyColorDark, currentBodyColorDark.opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 140, height: showZombie ? 60 : 40)
                    }
                    .offset(y: bodyBob)
                }
                .frame(height: 240)

                Spacer().frame(height: 24)

                // App name
                Text(L("onboarding.appName"))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)

                Spacer().frame(height: 8)

                Text(L("onboarding.subtitle"))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(BrainRotTheme.textSecondary)

                Spacer()

                // Bottom section
                VStack(spacing: 20) {
                    // Feature pills
                    HStack(spacing: 10) {
                        featurePill(icon: "chart.bar.fill", text: L("onboarding.trackUsage"))
                        featurePill(icon: "shield.fill", text: L("onboarding.blockApps"))
                        featurePill(icon: "brain.fill", text: L("onboarding.brainHealth"))
                    }

                    Text(L("onboarding.permission"))
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
                            Text(L("onboarding.getStarted"))
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
                            Text(L("onboarding.denied"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(BrainRotTheme.neonPink)

                            if let error = screenTimeManager.authError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(BrainRotTheme.textSecondary)
                            }

                            Text(L("onboarding.enableScreenTime"))
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
        .onDisappear { moodCycleTimer?.invalidate() }
    }

    // MARK: - Ecstatic Face (green kraken)

    private var ecstaticFace: some View {
        VStack(spacing: 4) {
            HStack(spacing: 20) {
                ZStack {
                    Circle().fill(Color.white).frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                    Text("\u{2605}").font(.system(size: 24, weight: .bold)).foregroundColor(bodyColorDark)
                    Circle().fill(Color.white).frame(width: 8, height: 8).offset(x: 6, y: -6)
                }
                ZStack {
                    Circle().fill(Color.white).frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                    Text("\u{2605}").font(.system(size: 24, weight: .bold)).foregroundColor(bodyColorDark)
                    Circle().fill(Color.white).frame(width: 8, height: 8).offset(x: 6, y: -6)
                }
            }
            HStack(spacing: 50) {
                Ellipse().fill(Color.pink.opacity(0.45)).frame(width: 20, height: 12)
                Ellipse().fill(Color.pink.opacity(0.45)).frame(width: 20, height: 12)
            }.offset(y: -2)
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(to: CGPoint(x: 28, y: 0), control: CGPoint(x: 14, y: 20))
                    p.closeSubpath()
                }.fill(Color(red: 0.92, green: 0.50, blue: 0.55).opacity(0.5)).frame(width: 28, height: 20)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(to: CGPoint(x: 28, y: 0), control: CGPoint(x: 14, y: 20))
                }.stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 28, height: 20)
            }
        }
        .offset(y: 8)
        .transition(.opacity)
    }

    // MARK: - Zombie Face (grey kraken)

    private var zombieFace: some View {
        VStack(spacing: 4) {
            // X eyes
            HStack(spacing: 20) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.7)).frame(width: 34, height: 34)
                    Path { p in
                        p.move(to: CGPoint(x: 3, y: 3)); p.addLine(to: CGPoint(x: 19, y: 19))
                        p.move(to: CGPoint(x: 19, y: 3)); p.addLine(to: CGPoint(x: 3, y: 19))
                    }
                    .stroke(Color(red: 0.35, green: 0.33, blue: 0.30), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 22, height: 22)
                }
                ZStack {
                    Circle().fill(Color.white.opacity(0.7)).frame(width: 34, height: 34)
                    Path { p in
                        p.move(to: CGPoint(x: 3, y: 3)); p.addLine(to: CGPoint(x: 19, y: 19))
                        p.move(to: CGPoint(x: 19, y: 3)); p.addLine(to: CGPoint(x: 3, y: 19))
                    }
                    .stroke(Color(red: 0.35, green: 0.33, blue: 0.30), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 22, height: 22)
                }
            }
            // Flat mouth + tongue
            VStack(spacing: 1) {
                Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 14, y: 0)) }
                    .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 14, height: 2)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.90, green: 0.50, blue: 0.55))
                    .frame(width: 7, height: 9)
                    .offset(y: 1)
            }
        }
        .offset(y: 8)
        .transition(.opacity)
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

        // Cycle between green (ecstatic) and grey (zombie) every 3 seconds
        moodCycleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                showZombie.toggle()
            }
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
