import SwiftUI

/// 圓形弧線健康分數環 — 取代 capsule badge
struct WellnessRing: View {
    let score: Int
    let level: HealthScoreLevel
    var diameter: CGFloat = 36

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: diameter * 0.07)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(ringColor, style: StrokeStyle(lineWidth: diameter * 0.07, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: score)

            // Score text
            Text("\(score)")
                .font(.system(size: diameter * 0.34, weight: .light, design: .rounded))
                .contentTransition(.numericText())
        }
        .frame(width: diameter, height: diameter)
    }

    private var ringColor: Color {
        switch level {
        case .excellent, .good: return ZenColors.bristolNormal
        case .fair: return ZenColors.amber
        case .poor: return .red
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        WellnessRing(score: 92, level: .excellent, diameter: 56)
        WellnessRing(score: 75, level: .good, diameter: 42)
        WellnessRing(score: 55, level: .fair, diameter: 36)
        WellnessRing(score: 25, level: .poor, diameter: 32)
    }
    .padding()
}
