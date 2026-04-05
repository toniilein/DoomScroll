import SwiftUI

// MARK: - Octopus Mood (4 tiers based on screen time minutes)

enum OctopusMood {
    case ecstatic    // < 4h:   Zen Master
    case happy       // 4-6h:   Casual Scroller
    case sad         // 6-8h:   Doomscroller
    case zombie      // 8h+:    Brainrot

    static func from(minutes: Double) -> OctopusMood {
        switch minutes {
        case ..<240: return .ecstatic
        case ..<360: return .happy
        case ..<480: return .sad
        default:     return .zombie
        }
    }

    /// Legacy score-based init for backward compat (day pills etc)
    static func from(score: Int) -> OctopusMood {
        switch score {
        case 0..<30:  return .ecstatic
        case 30..<60: return .happy
        case 60..<85: return .sad
        default:      return .zombie
        }
    }

    // MARK: Pastel Body Colors

    var bodyColor: Color {
        switch self {
        case .ecstatic: return Color(red: 0.55, green: 0.88, blue: 0.70)  // soft mint
        case .happy:    return Color(red: 0.96, green: 0.83, blue: 0.55)  // pastel amber
        case .sad:      return Color(red: 0.92, green: 0.58, blue: 0.55)  // pastel coral
        case .zombie:   return Color(red: 0.68, green: 0.65, blue: 0.63)  // warm gray
        }
    }

    var bodyColorDark: Color {
        switch self {
        case .ecstatic: return Color(red: 0.40, green: 0.75, blue: 0.55)
        case .happy:    return Color(red: 0.88, green: 0.70, blue: 0.38)  // pastel amber dark
        case .sad:      return Color(red: 0.80, green: 0.45, blue: 0.42)  // pastel coral dark
        case .zombie:   return Color(red: 0.52, green: 0.50, blue: 0.48)
        }
    }

    var spotColor: Color {
        switch self {
        case .ecstatic: return Color(red: 0.45, green: 0.78, blue: 0.58)
        case .happy:    return Color(red: 0.92, green: 0.75, blue: 0.45)  // pastel amber spot
        case .sad:      return Color(red: 0.85, green: 0.50, blue: 0.47)  // pastel coral spot
        case .zombie:   return Color(red: 0.58, green: 0.55, blue: 0.53)
        }
    }

    // MARK: Tentacle Motion

    var tentacleAmplitude: CGFloat {
        switch self {
        case .ecstatic: return 10
        case .happy:    return 8
        case .sad:      return 3
        case .zombie:   return 1
        }
    }

    var tentacleSpeed: Double {
        switch self {
        case .ecstatic: return 1.2
        case .happy:    return 1.8
        case .sad:      return 4.0
        case .zombie:   return 8.0
        }
    }

    var tentacleDroop: CGFloat {
        switch self {
        case .ecstatic: return 0
        case .happy:    return 3
        case .sad:      return 14
        case .zombie:   return 28
        }
    }

    // MARK: Face Details

    var showCheeks: Bool {
        self == .ecstatic || self == .happy
    }

    var cheekOpacity: Double {
        switch self {
        case .ecstatic: return 0.45
        case .happy:    return 0.35
        default:        return 0
        }
    }

    var particles: [String] {
        switch self {
        case .ecstatic: return ["\u{2728}", "\u{1F496}", "\u{2728}"]
        case .happy:    return ["\u{266A}", "\u{1F338}", "\u{266A}"]
        case .sad:      return ["\u{1F4A7}", "\u{1F622}", "\u{1F4A7}"]
        case .zombie:   return ["\u{1F480}", "\u{2620}\u{FE0F}", "\u{1F480}"]
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

// MARK: - Mini Octopus (static, matches big OctopusMascotView style)

struct MiniOctopusView: View {
    let mood: OctopusMood

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                // Round body (matches big octopus Circle + RadialGradient)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [mood.bodyColor, mood.bodyColorDark],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: s * 0.05,
                            endRadius: s * 0.4
                        )
                    )
                    .frame(width: s * 0.7, height: s * 0.7)
                    .shadow(color: mood.bodyColor.opacity(0.3), radius: 4, y: 2)
                    .offset(y: -s * 0.08)

                // Shine highlight
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.45), Color.clear],
                            center: .init(x: 0.4, y: 0.3),
                            startRadius: 0,
                            endRadius: s * 0.2
                        )
                    )
                    .frame(width: s * 0.4, height: s * 0.3)
                    .offset(x: -s * 0.05, y: -s * 0.2)

                // Spots
                Circle()
                    .fill(mood.spotColor.opacity(0.4))
                    .frame(width: s * 0.06, height: s * 0.06)
                    .offset(x: -s * 0.17, y: -s * 0.15)
                Circle()
                    .fill(mood.spotColor.opacity(0.3))
                    .frame(width: s * 0.045, height: s * 0.045)
                    .offset(x: s * 0.19, y: -s * 0.2)
                Circle()
                    .fill(mood.spotColor.opacity(0.35))
                    .frame(width: s * 0.05, height: s * 0.05)
                    .offset(x: s * 0.2, y: -s * 0.04)

                // Eyes (matching big octopus eye styles)
                miniEyes(s: s)
                    .offset(y: -s * 0.06)

                // Cheeks
                if mood.showCheeks {
                    HStack(spacing: s * 0.22) {
                        Ellipse()
                            .fill(Color.pink.opacity(mood.cheekOpacity))
                            .frame(width: s * 0.09, height: s * 0.055)
                        Ellipse()
                            .fill(Color.pink.opacity(mood.cheekOpacity))
                            .frame(width: s * 0.09, height: s * 0.055)
                    }
                    .offset(y: s * 0.02)
                }

                // Mouth
                miniMouth(s: s)
                    .offset(y: s * 0.07)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func miniEyes(s: CGFloat) -> some View {
        HStack(spacing: s * 0.1) {
            miniEye(s: s, isLeft: true)
            miniEye(s: s, isLeft: false)
        }
    }

    @ViewBuilder
    private func miniEye(s: CGFloat, isLeft: Bool) -> some View {
        switch mood {
        case .ecstatic:
            // Star eyes
            ZStack {
                Circle().fill(Color.white)
                    .frame(width: s * 0.17, height: s * 0.17)
                Text("\u{2605}")
                    .font(.system(size: s * 0.12, weight: .bold))
                    .foregroundColor(mood.bodyColorDark)
            }
        case .happy:
            // Curved happy eyes (^_^)
            Path { p in
                p.move(to: CGPoint(x: 0, y: s * 0.06))
                p.addQuadCurve(
                    to: CGPoint(x: s * 0.12, y: s * 0.06),
                    control: CGPoint(x: s * 0.06, y: 0)
                )
            }
            .stroke(mood.bodyColorDark, style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round))
            .frame(width: s * 0.12, height: s * 0.08)
        case .sad:
            // Big worried eyes
            ZStack {
                Ellipse().fill(Color.white)
                    .frame(width: s * 0.17, height: s * 0.16)
                Circle()
                    .fill(Color(red: 0.25, green: 0.22, blue: 0.30))
                    .frame(width: s * 0.08, height: s * 0.08)
                Circle()
                    .fill(Color.white)
                    .frame(width: s * 0.03, height: s * 0.03)
                    .offset(x: s * 0.015, y: -s * 0.015)
            }
        case .zombie:
            // X eyes
            ZStack {
                Ellipse().fill(Color.white)
                    .frame(width: s * 0.17, height: s * 0.16)
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.25, green: 0.22, blue: 0.30))
                        .frame(width: s * 0.1, height: s * 0.02)
                        .rotationEffect(.degrees(45))
                    Rectangle()
                        .fill(Color(red: 0.25, green: 0.22, blue: 0.30))
                        .frame(width: s * 0.1, height: s * 0.02)
                        .rotationEffect(.degrees(-45))
                }
            }
        }
    }

    @ViewBuilder
    private func miniMouth(s: CGFloat) -> some View {
        switch mood {
        case .ecstatic:
            // Wide open smile
            Capsule()
                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                .frame(width: s * 0.14, height: s * 0.07)
        case .happy:
            // Gentle smile
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(
                    to: CGPoint(x: s * 0.12, y: 0),
                    control: CGPoint(x: s * 0.06, y: s * 0.06)
                )
            }
            .stroke(Color(red: 0.15, green: 0.15, blue: 0.2), style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
            .frame(width: s * 0.12, height: s * 0.06)
        case .sad:
            // Wobbly frown
            Path { p in
                p.move(to: CGPoint(x: 0, y: s * 0.04))
                p.addQuadCurve(
                    to: CGPoint(x: s * 0.1, y: s * 0.04),
                    control: CGPoint(x: s * 0.05, y: 0)
                )
            }
            .stroke(Color(red: 0.15, green: 0.15, blue: 0.2), style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
            .frame(width: s * 0.1, height: s * 0.05)
        case .zombie:
            // Wavy dizzy mouth
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .frame(width: s * 0.12, height: s * 0.02)
                    .rotationEffect(.degrees(15))
            }
        }
    }
}

private struct MiniTentacles: View {
    let mood: OctopusMood

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                let count = 5
                let spacing = w / CGFloat(count + 1)
                for i in 0..<count {
                    let x = spacing * CGFloat(i + 1)
                    path.move(to: CGPoint(x: x, y: 0))
                    let wave = CGFloat(i % 2 == 0 ? 1 : -1) * 3
                    path.addQuadCurve(
                        to: CGPoint(x: x + wave, y: h),
                        control: CGPoint(x: x - wave * 1.5, y: h * 0.5)
                    )
                }
            }
            .stroke(mood.bodyColorDark, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

// MARK: - Main View

struct OctopusMascotView: View {
    let score: Int
    let totalScreenTime: String
    var totalDurationSeconds: TimeInterval = 0

    @State private var wavePhase: CGFloat = 0
    @State private var bodyBob: CGFloat = 0
    @State private var glowPulse = false
    @State private var particleDrift: CGFloat = 0
    @State private var particleFade: Double = 1
    @State private var eyeBlink: Bool = false
    @State private var showTierSheet = false

    private var mood: OctopusMood { .from(minutes: totalDurationSeconds / 60.0) }
    private var totalMinutes: Double { totalDurationSeconds / 60.0 }

    // MARK: Body

    var body: some View {
        VStack(spacing: 8) {
            // Speech bubble
            speechBubble
                .padding(.horizontal, 20)

            // Character area
            ZStack {
                Circle()
                    .fill(mood.bodyColor.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .scaleEffect(glowPulse ? 1.1 : 0.92)

                floatingParticles

                VStack(spacing: -25) {
                    octopusBody
                    tentacles
                }
                .offset(y: bodyBob)
                .onTapGesture { showTierSheet = true }
            }
            .frame(height: 220)

            // Daily screen time with label
            HStack(spacing: 6) {
                Text(L("octopus.screentime"))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
                Text(totalScreenTime)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(BrainRotTheme.textPrimary)
            }

            // Tier status bar
            tierStatusBar
                .padding(.horizontal, 20)
        }
        .onAppear { startAnimations() }
        .sheet(isPresented: $showTierSheet) {
            tierGallerySheet
        }
    }

    // MARK: - Tier Definitions

    private static var tiers: [(name: String, emoji: String, minMinutes: Double, maxMinutes: Double, mood: OctopusMood)] {
        [
            (L("tier.zenMaster"),      "\u{1F9D8}", 0,   240, .ecstatic),
            (L("tier.casualScroller"), "\u{1F4F1}", 240, 360, .happy),
            (L("tier.doomscroller"),   "\u{1F480}", 360, 480, .sad),
            (L("tier.brainrot"),       "\u{1F9E0}", 480, .infinity, .zombie),
        ]
    }

    private static func formatHM(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: - Tier Status Bar

    private var tierStatusBar: some View {
        let currentTierIdx = Self.tiers.firstIndex(where: { totalMinutes < $0.maxMinutes }) ?? Self.tiers.count - 1

        return VStack(spacing: 6) {
            // Combined progress bar with position indicator
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let tierCount = CGFloat(Self.tiers.count)
                let gap: CGFloat = 3
                let tierWidth = (totalWidth - gap * (tierCount - 1)) / tierCount

                ZStack(alignment: .leading) {
                    // Tier segments
                    HStack(spacing: gap) {
                        ForEach(Array(Self.tiers.enumerated()), id: \.offset) { idx, tier in
                            let isCurrent = idx == currentTierIdx
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    isCurrent
                                        ? LinearGradient(colors: [tier.mood.bodyColor, tier.mood.bodyColorDark], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [tier.mood.bodyColor.opacity(0.25), tier.mood.bodyColorDark.opacity(0.25)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(height: 8)
                                .overlay(
                                    isCurrent
                                        ? RoundedRectangle(cornerRadius: 3)
                                            .stroke(tier.mood.bodyColorDark, lineWidth: 1)
                                        : nil
                                )
                        }
                    }

                    // Position indicator line
                    let currentTier = Self.tiers[currentTierIdx]
                    let progressInTier: CGFloat = {
                        let range = currentTier.maxMinutes == .infinity ? 240.0 : (currentTier.maxMinutes - currentTier.minMinutes)
                        return min(1.0, CGFloat((totalMinutes - currentTier.minMinutes) / range))
                    }()
                    let segmentStart = CGFloat(currentTierIdx) * (tierWidth + gap)
                    let xPos = segmentStart + tierWidth * progressInTier

                    // Dot indicator
                    Circle()
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 2)
                        .offset(x: xPos - 5, y: 0)
                }
            }
            .frame(height: 18)

            // Tier labels
            HStack(spacing: 3) {
                ForEach(Array(Self.tiers.enumerated()), id: \.offset) { idx, tier in
                    let isCurrent = idx == currentTierIdx
                    Text(tier.name)
                        .font(.system(size: 9, weight: isCurrent ? .black : .medium, design: .rounded))
                        .foregroundColor(isCurrent ? tier.mood.bodyColorDark : BrainRotTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    // MARK: - Tier Gallery Sheet

    private var tierGallerySheet: some View {
        let currentTierIdx = Self.tiers.firstIndex(where: { totalMinutes < $0.maxMinutes }) ?? Self.tiers.count - 1

        return NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(Self.tiers.enumerated()), id: \.offset) { idx, tier in
                        let isCurrent = idx == currentTierIdx

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [tier.mood.bodyColor, tier.mood.bodyColorDark],
                                            center: .init(x: 0.4, y: 0.35),
                                            startRadius: 5,
                                            endRadius: 25
                                        )
                                    )
                                    .frame(width: 50, height: 50)

                                Text(tier.emoji)
                                    .font(.system(size: 22))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(tier.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(isCurrent ? tier.mood.bodyColorDark : BrainRotTheme.textPrimary)
                                    if isCurrent {
                                        Text(L("tier.current"))
                                            .font(.system(size: 9, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(tier.mood.bodyColorDark)
                                            .clipShape(Capsule())
                                    }
                                }

                                let rangeText: String = {
                                    if tier.maxMinutes == .infinity {
                                        return "\(Self.formatHM(tier.minMinutes))+"
                                    }
                                    return "\(Self.formatHM(tier.minMinutes))\u{2013}\(Self.formatHM(tier.maxMinutes))"
                                }()

                                Text(rangeText)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(BrainRotTheme.textSecondary)
                            }

                            Spacer()

                            if isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(tier.mood.bodyColorDark)
                            }
                        }
                        .padding(14)
                        .background(isCurrent ? tier.mood.bodyColor.opacity(0.12) : BrainRotTheme.cardBorder.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isCurrent ? tier.mood.bodyColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                    }
                }
                .padding()
            }
            .background(BrainRotTheme.background)
            .navigationTitle(L("tier.krakenTiers"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("tier.done")) { showTierSheet = false }
                }
            }
        }
    }

    // MARK: - Speech Bubble

    private var speechBubbleText: String {
        let currentTierIdx = Self.tiers.firstIndex(where: { totalMinutes < $0.maxMinutes }) ?? Self.tiers.count - 1

        // Time until next worse tier
        if currentTierIdx < Self.tiers.count - 1 {
            let nextTier = Self.tiers[currentTierIdx + 1]
            let remaining = nextTier.minMinutes - totalMinutes

            if remaining > 0 {
                let fmt = BrainRotCalculator.formatDuration(remaining * 60)
                switch mood {
                case .ecstatic:
                    return String(format: L("octopus.ecstatic.timeLeft"), fmt)
                case .happy:
                    return String(format: L("octopus.happy.timeLeft"), fmt)
                case .sad:
                    return String(format: L("octopus.sad.timeLeft"), fmt)
                case .zombie:
                    return "..."
                }
            }
        }

        // Already at worst or no time remaining
        switch mood {
        case .ecstatic: return String(format: L("octopus.ecstatic.noTime"), totalScreenTime)
        case .happy:    return String(format: L("octopus.happy.noTime"), totalScreenTime)
        case .sad:      return String(format: L("octopus.sad.noTime"), totalScreenTime)
        case .zombie:   return String(format: L("octopus.zombie.noTime"), totalScreenTime)
        }
    }

    private var speechBubble: some View {
        HStack {
            Text(speechBubbleText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(BrainRotTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(BrainRotTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(mood.bodyColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Baby Octopus Body

    private var octopusBody: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [mood.bodyColor, mood.bodyColorDark],
                        center: .init(x: 0.4, y: 0.35),
                        startRadius: 12,
                        endRadius: 90
                    )
                )
                .frame(width: 160, height: 160)
                .shadow(color: mood.bodyColor.opacity(0.35), radius: 12, y: 6)

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

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.50), Color.clear],
                        center: .init(x: 0.4, y: 0.3),
                        startRadius: 0,
                        endRadius: 45
                    )
                )
                .frame(width: 110, height: 88)
                .offset(x: -14, y: -26)

            Ellipse()
                .fill(Color.white.opacity(0.25))
                .frame(width: 18, height: 11)
                .rotationEffect(.degrees(-25))
                .offset(x: -38, y: -44)

            VStack(spacing: 2) {
                HStack(spacing: 12) {
                    babyEyeView(isLeft: true)
                    babyEyeView(isLeft: false)
                }

                if mood.showCheeks {
                    HStack(spacing: 44) {
                        Ellipse()
                            .fill(Color.pink.opacity(mood.cheekOpacity))
                            .frame(width: 22, height: 13)
                        Ellipse()
                            .fill(Color.pink.opacity(mood.cheekOpacity))
                            .frame(width: 22, height: 13)
                    }
                    .offset(y: -2)
                }

                mouthView
            }
            .offset(y: 8)
        }
    }

    // MARK: - Baby Eyes

    @ViewBuilder
    private func babyEyeView(isLeft: Bool) -> some View {
        switch mood {
        case .ecstatic:
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                Text("\u{2605}")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(mood.bodyColorDark)
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .offset(x: 8, y: -8)
            }

        case .happy:
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 24))
                    p.addQuadCurve(
                        to: CGPoint(x: 34, y: 24),
                        control: CGPoint(x: 17, y: 3)
                    )
                }
                .stroke(mood.bodyColorDark, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                .frame(width: 34, height: 28)

                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .offset(x: isLeft ? -8 : 8, y: 8)
            }

        case .sad:
            ZStack {
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 48, height: 46)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.35, green: 0.32, blue: 0.42),
                                Color(red: 0.20, green: 0.18, blue: 0.25)
                            ],
                            center: .center, startRadius: 0, endRadius: 14
                        )
                    )
                    .frame(width: 26, height: 26)
                    .offset(y: 4)

                Ellipse()
                    .fill(mood.bodyColor)
                    .frame(width: 52, height: 20)
                    .offset(y: -18)

                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: 5, y: -2)

                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(x: -5, y: 6)

                if isLeft {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.82, blue: 0.98),
                                    Color(red: 0.50, green: 0.72, blue: 0.95)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 9, height: 13)
                        .offset(x: -16, y: 18)
                }
            }

        case .zombie:
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 46, height: 46)
                Path { p in
                    p.move(to: CGPoint(x: 3, y: 3))
                    p.addLine(to: CGPoint(x: 25, y: 25))
                    p.move(to: CGPoint(x: 25, y: 3))
                    p.addLine(to: CGPoint(x: 3, y: 25))
                }
                .stroke(
                    Color(red: 0.35, green: 0.33, blue: 0.30),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .frame(width: 28, height: 28)
            }
        }
    }

    // MARK: - Mouth

    @ViewBuilder
    private var mouthView: some View {
        switch mood {
        case .ecstatic:
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

        case .happy:
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(to: CGPoint(x: 20, y: 0), control: CGPoint(x: 10, y: 12))
            }
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 20, height: 12)

        case .sad:
            Path { p in
                p.move(to: CGPoint(x: 0, y: 8))
                p.addQuadCurve(to: CGPoint(x: 18, y: 8), control: CGPoint(x: 9, y: 0))
            }
            .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 18, height: 10)

        case .zombie:
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
