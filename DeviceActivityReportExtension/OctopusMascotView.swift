import SwiftUI

// MARK: - Octopus Mood

enum OctopusMood {
    case ecstatic    // Score 0-19:  Digital Monk
    case happy       // Score 20-39: Grass Toucher
    case neutral     // Score 40-59: Casual Scroller
    case sad         // Score 60-79: Doomscroller
    case distressed  // Score 80-94: Brainrot Mode
    case zombie      // Score 95-99: Full Brainrot

    static func from(score: Int) -> OctopusMood {
        switch score {
        case 0..<20:  return .ecstatic
        case 20..<40: return .happy
        case 40..<60: return .neutral
        case 60..<80: return .sad
        case 80..<95: return .distressed
        default:      return .zombie
        }
    }

    // MARK: Pastel Body Colors

    var bodyColor: Color {
        switch self {
        case .ecstatic:   return Color(red: 0.55, green: 0.88, blue: 0.70)  // soft mint
        case .happy:      return Color(red: 0.52, green: 0.82, blue: 0.78)  // seafoam
        case .neutral:    return Color(red: 0.60, green: 0.74, blue: 0.90)  // baby blue
        case .sad:        return Color(red: 0.75, green: 0.62, blue: 0.88)  // lavender
        case .distressed: return Color(red: 0.92, green: 0.58, blue: 0.58)  // soft coral
        case .zombie:     return Color(red: 0.68, green: 0.65, blue: 0.63)  // warm gray
        }
    }

    var bodyColorDark: Color {
        switch self {
        case .ecstatic:   return Color(red: 0.40, green: 0.75, blue: 0.55)
        case .happy:      return Color(red: 0.38, green: 0.70, blue: 0.65)
        case .neutral:    return Color(red: 0.48, green: 0.62, blue: 0.78)
        case .sad:        return Color(red: 0.62, green: 0.48, blue: 0.75)
        case .distressed: return Color(red: 0.80, green: 0.45, blue: 0.45)
        case .zombie:     return Color(red: 0.52, green: 0.50, blue: 0.48)
        }
    }

    var spotColor: Color {
        switch self {
        case .ecstatic:   return Color(red: 0.45, green: 0.78, blue: 0.58)
        case .happy:      return Color(red: 0.42, green: 0.72, blue: 0.68)
        case .neutral:    return Color(red: 0.50, green: 0.65, blue: 0.82)
        case .sad:        return Color(red: 0.65, green: 0.52, blue: 0.78)
        case .distressed: return Color(red: 0.82, green: 0.48, blue: 0.48)
        case .zombie:     return Color(red: 0.58, green: 0.55, blue: 0.53)
        }
    }

    // MARK: Tentacle Motion

    var tentacleAmplitude: CGFloat {
        switch self {
        case .ecstatic:   return 10
        case .happy:      return 8
        case .neutral:    return 5
        case .sad:        return 3
        case .distressed: return 2
        case .zombie:     return 1
        }
    }

    var tentacleSpeed: Double {
        switch self {
        case .ecstatic:   return 1.2
        case .happy:      return 1.8
        case .neutral:    return 2.8
        case .sad:        return 4.0
        case .distressed: return 5.5
        case .zombie:     return 8.0
        }
    }

    var tentacleDroop: CGFloat {
        switch self {
        case .ecstatic:   return 0
        case .happy:      return 3
        case .neutral:    return 8
        case .sad:        return 14
        case .distressed: return 20
        case .zombie:     return 28
        }
    }

    // MARK: Face Details

    var showCheeks: Bool {
        self == .ecstatic || self == .happy || self == .neutral
    }

    var cheekOpacity: Double {
        switch self {
        case .ecstatic: return 0.45
        case .happy:    return 0.35
        case .neutral:  return 0.20
        default:        return 0
        }
    }

    var particles: [String] {
        switch self {
        case .ecstatic:   return ["✨", "💖", "✨"]
        case .happy:      return ["♪", "🌸", "♪"]
        case .neutral:    return ["💧", "📱", "💧"]
        case .sad:        return ["💧", "😢", "💧"]
        case .distressed: return ["🧠", "💫", "🧠"]
        case .zombie:     return ["💀", "☠️", "💀"]
        }
    }
}

// MARK: - Tentacles Shape

struct TentaclesShape: Shape {
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

// MARK: - Main View

struct OctopusMascotView: View {
    let score: Int
    let totalScreenTime: String

    @State private var wavePhase: CGFloat = 0
    @State private var bodyBob: CGFloat = 0
    @State private var glowPulse = false
    @State private var particleDrift: CGFloat = 0
    @State private var particleFade: Double = 1
    @State private var eyeBlink: Bool = false

    private var mood: OctopusMood { .from(score: score) }

    // MARK: Body

    var body: some View {
        VStack(spacing: 8) {
            // ── Character area ──
            ZStack {
                // Soft glow
                Circle()
                    .fill(mood.bodyColor.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .scaleEffect(glowPulse ? 1.1 : 0.92)

                // Floating particle decorations
                floatingParticles

                // Octopus character
                VStack(spacing: -10) {
                    octopusBody
                    tentacles
                }
                .offset(y: bodyBob)
            }
            .frame(height: 240)

            // ── Score info ──
            scoreDisplay
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Baby Octopus Body

    private var octopusBody: some View {
        ZStack {
            // Round chubby body — baby proportions
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            mood.bodyColor,
                            mood.bodyColorDark
                        ],
                        center: .init(x: 0.4, y: 0.35),
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: mood.bodyColor.opacity(0.35), radius: 12, y: 6)

            // Cute body spots (like a baby octopus)
            Group {
                Circle()
                    .fill(mood.spotColor.opacity(0.4))
                    .frame(width: 12, height: 12)
                    .offset(x: -35, y: -20)

                Circle()
                    .fill(mood.spotColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(x: 38, y: -30)

                Circle()
                    .fill(mood.spotColor.opacity(0.35))
                    .frame(width: 10, height: 10)
                    .offset(x: 42, y: 5)
            }

            // Big shiny highlight — makes it look squishy/round
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

            // Small secondary highlight
            Ellipse()
                .fill(Color.white.opacity(0.25))
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(-25))
                .offset(x: -32, y: -38)

            // Face — positioned in center-lower area of the round body
            VStack(spacing: 4) {
                // Big baby eyes
                HStack(spacing: 20) {
                    babyEyeView(isLeft: true)
                    babyEyeView(isLeft: false)
                }

                // Rosy cheeks
                if mood.showCheeks {
                    HStack(spacing: 50) {
                        Ellipse()
                            .fill(Color.pink.opacity(mood.cheekOpacity))
                            .frame(width: 20, height: 12)
                        Ellipse()
                            .fill(Color.pink.opacity(mood.cheekOpacity))
                            .frame(width: 20, height: 12)
                    }
                    .offset(y: -2)
                }

                // Little mouth
                mouthView
            }
            .offset(y: 8)
        }
    }

    // MARK: - Baby Eyes (oversized!)

    @ViewBuilder
    private func babyEyeView(isLeft: Bool) -> some View {
        switch mood {
        case .ecstatic:
            // Giant sparkly star eyes
            ZStack {
                // White sclera
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)

                // Star pupil
                Text("★")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(mood.bodyColorDark)

                // Sparkle highlight
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(x: 6, y: -6)
            }

        case .happy:
            // Big happy squint eyes  ◠‿◠
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 18))
                    p.addQuadCurve(
                        to: CGPoint(x: 26, y: 18),
                        control: CGPoint(x: 13, y: 2)
                    )
                }
                .stroke(
                    mood.bodyColorDark,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .frame(width: 26, height: 22)

                // Little lash/highlight
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 5, height: 5)
                    .offset(x: isLeft ? -6 : 6, y: 6)
            }

        case .neutral:
            // Big round worried baby eyes
            ZStack {
                // Sclera
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)

                // Big iris
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.30, green: 0.30, blue: 0.38),
                                Color(red: 0.18, green: 0.18, blue: 0.22)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 9
                        )
                    )
                    .frame(width: 18, height: 18)
                    .offset(x: isLeft ? -2 : 2, y: 2)

                // Big cute highlight
                Circle()
                    .fill(Color.white)
                    .frame(width: 9, height: 9)
                    .offset(x: isLeft ? 2 : 6, y: -4)

                // Small secondary highlight
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 4, height: 4)
                    .offset(x: isLeft ? -3 : 1, y: 4)
            }

        case .sad:
            // Big watery puppy eyes with tear
            ZStack {
                // Sclera — slightly oval for droopy look
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 36, height: 34)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)

                // Big watery iris
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.35, green: 0.32, blue: 0.42),
                                Color(red: 0.20, green: 0.18, blue: 0.25)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
                    .frame(width: 20, height: 20)
                    .offset(y: 3)

                // Droopy eyelid
                Ellipse()
                    .fill(mood.bodyColor)
                    .frame(width: 40, height: 16)
                    .offset(y: -14)

                // Watery shine — bigger for sad puppy look
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .offset(x: 4, y: -2)

                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 5, height: 5)
                    .offset(x: -4, y: 5)

                // Tear drop on one eye
                if isLeft {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.82, blue: 0.98),
                                    Color(red: 0.50, green: 0.72, blue: 0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 7, height: 10)
                        .offset(x: -12, y: 14)
                }
            }

        case .distressed:
            // Big dizzy spiral eyes
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)

                // Spiral
                Text("@")
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.30))

                // Faint highlight
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .offset(x: 6, y: -6)
            }

        case .zombie:
            // Big X_X dead eyes
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 34, height: 34)

                Path { p in
                    p.move(to: CGPoint(x: 3, y: 3))
                    p.addLine(to: CGPoint(x: 19, y: 19))
                    p.move(to: CGPoint(x: 19, y: 3))
                    p.addLine(to: CGPoint(x: 3, y: 19))
                }
                .stroke(
                    Color(red: 0.35, green: 0.33, blue: 0.30),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .frame(width: 22, height: 22)
            }
        }
    }

    // MARK: - Mouth

    @ViewBuilder
    private var mouthView: some View {
        switch mood {
        case .ecstatic:
            // Big open happy smile with rosy interior
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(
                        to: CGPoint(x: 28, y: 0),
                        control: CGPoint(x: 14, y: 20)
                    )
                    p.closeSubpath()
                }
                .fill(Color(red: 0.92, green: 0.50, blue: 0.55).opacity(0.5))
                .frame(width: 28, height: 20)

                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(
                        to: CGPoint(x: 28, y: 0),
                        control: CGPoint(x: 14, y: 20)
                    )
                }
                .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 28, height: 20)
            }

        case .happy:
            // Cute little smile ‿
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(
                    to: CGPoint(x: 20, y: 0),
                    control: CGPoint(x: 10, y: 12)
                )
            }
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 20, height: 12)

        case .neutral:
            // Tiny "o" surprise mouth
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 10, height: 10)

        case .sad:
            // Little frown ︵
            Path { p in
                p.move(to: CGPoint(x: 0, y: 8))
                p.addQuadCurve(
                    to: CGPoint(x: 18, y: 8),
                    control: CGPoint(x: 9, y: 0)
                )
            }
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 18, height: 10)

        case .distressed:
            // Wavy wobbly mouth
            Path { p in
                p.move(to: CGPoint(x: 0, y: 6))
                p.addCurve(
                    to: CGPoint(x: 22, y: 6),
                    control1: CGPoint(x: 7, y: 0),
                    control2: CGPoint(x: 15, y: 12)
                )
            }
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 22, height: 12)

        case .zombie:
            // Flat line + little tongue
            VStack(spacing: 1) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: 14, y: 0))
                }
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 14, height: 2)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.90, green: 0.50, blue: 0.55))
                    .frame(width: 7, height: 9)
                    .offset(y: 1)
            }
        }
    }

    // MARK: - Stubby Baby Tentacles

    private var tentacles: some View {
        TentaclesShape(
            phase: wavePhase,
            amplitude: mood.tentacleAmplitude,
            droop: mood.tentacleDroop
        )
        .stroke(
            LinearGradient(
                colors: [mood.bodyColorDark, mood.bodyColorDark.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            ),
            style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
        )
        .frame(width: 140, height: 40 + mood.tentacleDroop)
    }

    // MARK: - Floating Particles

    private var floatingParticles: some View {
        let emojis = mood.particles
        return ZStack {
            Text(emojis[0])
                .font(.system(size: 20))
                .offset(x: -65, y: -60 + particleDrift * 0.7)
                .opacity(particleFade)

            Text(emojis[1])
                .font(.system(size: 16))
                .offset(x: 70, y: -40 + particleDrift)
                .opacity(particleFade * 0.7)

            Text(emojis[2])
                .font(.system(size: 14))
                .offset(x: 55, y: -75 + particleDrift * 0.5)
                .opacity(particleFade * 0.5)
        }
    }

    // MARK: - Score Display

    private var tierInfo: (name: String, emoji: String, nextName: String?, nextEmoji: String?, progress: Double) {
        let tiers: [(name: String, emoji: String, min: Int, max: Int)] = [
            ("Digital Monk",    "\u{2728}", 0,  19),
            ("Grass Toucher",   "\u{266A}", 20, 39),
            ("Casual Scroller", "\u{1F4F1}", 40, 59),
            ("Doomscroller",    "\u{1F62E}", 60, 79),
            ("Brainrot Mode",   "\u{1F9E0}", 80, 94),
            ("Full Brainrot",   "\u{1F480}", 95, 100),
        ]

        let idx = tiers.firstIndex(where: { score >= $0.min && score <= $0.max }) ?? tiers.count - 1
        let current = tiers[idx]

        if idx == 0 {
            // Already best tier
            let progress = 1.0 - Double(score) / Double(current.max + 1)
            return (current.name, current.emoji, nil, nil, progress)
        }

        let next = tiers[idx - 1]
        let range = Double(current.max - current.min)
        let progress = range > 0 ? Double(current.max - score) / range : 1.0
        return (current.name, current.emoji, next.name, next.emoji, progress)
    }

    private var scoreDisplay: some View {
        let info = tierInfo

        return VStack(spacing: 8) {
            // Tier badge
            HStack(spacing: 6) {
                Text(info.emoji)
                    .font(.system(size: 16))
                Text(info.name)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(mood.bodyColor.opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(mood.bodyColor.opacity(0.4), lineWidth: 1)
            )

            // Screen time
            Text(totalScreenTime)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(BrainRotTheme.textSecondary)

            // Progress bar to next tier
            if let nextName = info.nextName, let nextEmoji = info.nextEmoji {
                VStack(spacing: 6) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(BrainRotTheme.cardBorder)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [mood.bodyColor, mood.bodyColorDark],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0, min(1, info.progress)) * 220,
                                height: 8
                            )
                    }
                    .frame(width: 220)

                    // Next tier label
                    HStack(spacing: 4) {
                        Text("Next:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BrainRotTheme.textSecondary)
                        Text(nextEmoji)
                            .font(.system(size: 12))
                        Text(nextName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(BrainRotTheme.textPrimary)
                    }
                }
            } else {
                Text("You're at the top! \u{1F451}")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(BrainRotTheme.neonGreen)
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(
            .linear(duration: mood.tentacleSpeed)
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
