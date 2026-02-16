import SwiftUI

/// 抽象幾何症狀圖標 — 取代 emoji
struct SymptomIconView: View {
    let type: SymptomType
    var color: Color = .secondary
    var size: CGFloat = 22

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width
            let scale = s / 22  // reference viewBox is 22×22

            switch type {
            case .abdominalPain: drawPain(context: context, scale: scale)
            case .bloating: drawBloat(context: context, scale: scale)
            case .nausea: drawNausea(context: context, scale: scale)
            case .fatigue: drawFatigue(context: context, scale: scale)
            case .cramping: drawCramp(context: context, scale: scale)
            case .gas: drawGas(context: context, scale: scale)
            case .bowelSounds: drawBowelSounds(context: context, scale: scale)
            case .fever: drawFever(context: context, scale: scale)
            case .jointPain: drawJoint(context: context, scale: scale)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - 腹痛: 圓 + 4 放射線

    private func drawPain(context: GraphicsContext, scale: CGFloat) {
        let center = CGPoint(x: 11 * scale, y: 11 * scale)
        let r: CGFloat = 4 * scale
        let circle = Circle().path(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        context.stroke(circle, with: .color(color), lineWidth: 1.5 * scale / 1.1)

        let lines: [(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat)] = [
            (11, 3, 11, 5.5),
            (11, 16.5, 11, 19),
            (3, 11, 5.5, 11),
            (16.5, 11, 19, 11),
        ]
        for l in lines {
            var path = Path()
            path.move(to: CGPoint(x: l.x1 * scale, y: l.y1 * scale))
            path.addLine(to: CGPoint(x: l.x2 * scale, y: l.y2 * scale))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.2 * scale / 1.1, lineCap: .round))
        }
    }

    // MARK: - 腹脹: 同心圓

    private func drawBloat(context: GraphicsContext, scale: CGFloat) {
        let center = CGPoint(x: 11 * scale, y: 11 * scale)

        // Inner filled circle
        let innerR: CGFloat = 3 * scale
        let innerRect = CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2)
        context.fill(Circle().path(in: innerRect), with: .color(color.opacity(0.25)))

        // Outer filled circle (subtle)
        let outerR: CGFloat = 5 * scale
        let outerRect = CGRect(x: center.x - outerR, y: center.y - outerR, width: outerR * 2, height: outerR * 2)
        context.fill(Circle().path(in: outerRect), with: .color(color.opacity(0.15)))

        // Outer dashed stroke
        context.stroke(
            Circle().path(in: outerRect),
            with: .color(color),
            style: StrokeStyle(lineWidth: 1.2 * scale / 1.1, dash: [2 * scale, 2 * scale])
        )
    }

    // MARK: - 噁心: 正弦波

    private func drawNausea(context: GraphicsContext, scale: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: 3 * scale, y: 11 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 9 * scale, y: 11 * scale),
            control: CGPoint(x: 6 * scale, y: 6 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 15 * scale, y: 11 * scale),
            control: CGPoint(x: 12 * scale, y: 16 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 21 * scale, y: 11 * scale),
            control: CGPoint(x: 18 * scale, y: 6 * scale)
        )
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5 * scale / 1.1, lineCap: .round))

        // Subtle second wave
        var path2 = Path()
        path2.move(to: CGPoint(x: 3 * scale, y: 15 * scale))
        path2.addQuadCurve(
            to: CGPoint(x: 9 * scale, y: 15 * scale),
            control: CGPoint(x: 6 * scale, y: 10 * scale)
        )
        context.stroke(path2, with: .color(color.opacity(0.4)), style: StrokeStyle(lineWidth: 1 * scale / 1.1, lineCap: .round))
    }

    // MARK: - 疲倦: 下垂曲線 + 圓點

    private func drawFatigue(context: GraphicsContext, scale: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: 4 * scale, y: 8 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 11 * scale, y: 12 * scale),
            control: CGPoint(x: 8 * scale, y: 8 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 18 * scale, y: 16 * scale),
            control: CGPoint(x: 14 * scale, y: 16 * scale)
        )
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5 * scale / 1.1, lineCap: .round))

        let dotR: CGFloat = 1.5 * scale
        let dotRect = CGRect(x: 18 * scale - dotR, y: 16 * scale - dotR, width: dotR * 2, height: dotR * 2)
        context.fill(Circle().path(in: dotRect), with: .color(color.opacity(0.5)))
    }

    // MARK: - 絞痛: 鋸齒折線

    private func drawCramp(context: GraphicsContext, scale: CGFloat) {
        var path = Path()
        let points: [(CGFloat, CGFloat)] = [(4, 8), (8, 15), (12, 6), (16, 16), (20, 9)]
        path.move(to: CGPoint(x: points[0].0 * scale, y: points[0].1 * scale))
        for i in 1..<points.count {
            path.addLine(to: CGPoint(x: points[i].0 * scale, y: points[i].1 * scale))
        }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5 * scale / 1.1, lineCap: .round, lineJoin: .round))
    }

    // MARK: - 脹氣: 上升氣泡

    private func drawGas(context: GraphicsContext, scale: CGFloat) {
        // Empty bowl shape (appetite/gas)
        var bowl = Path()
        bowl.move(to: CGPoint(x: 4 * scale, y: 10 * scale))
        bowl.addQuadCurve(
            to: CGPoint(x: 18 * scale, y: 10 * scale),
            control: CGPoint(x: 11 * scale, y: 19 * scale)
        )
        context.stroke(bowl, with: .color(color), style: StrokeStyle(lineWidth: 1.3 * scale / 1.1, lineCap: .round))

        // Rising bubbles
        let bubbles: [(cx: CGFloat, cy: CGFloat, r: CGFloat)] = [
            (8, 6, 1.2),
            (12, 4, 1.0),
            (16, 6.5, 0.8),
        ]
        for b in bubbles {
            let rect = CGRect(
                x: (b.cx - b.r) * scale,
                y: (b.cy - b.r) * scale,
                width: b.r * 2 * scale,
                height: b.r * 2 * scale
            )
            context.stroke(Circle().path(in: rect), with: .color(color.opacity(0.6)), lineWidth: 0.8 * scale)
        }
    }

    // MARK: - 腸鳴: 聲波弧線

    private func drawBowelSounds(context: GraphicsContext, scale: CGFloat) {
        let center = CGPoint(x: 7 * scale, y: 11 * scale)
        // Small arc
        var arc1 = Path()
        arc1.addArc(center: center, radius: 4 * scale, startAngle: .degrees(-45), endAngle: .degrees(45), clockwise: false)
        context.stroke(arc1, with: .color(color), style: StrokeStyle(lineWidth: 1.3 * scale / 1.1, lineCap: .round))

        // Medium arc
        var arc2 = Path()
        arc2.addArc(center: center, radius: 7 * scale, startAngle: .degrees(-40), endAngle: .degrees(40), clockwise: false)
        context.stroke(arc2, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: 1.1 * scale / 1.1, lineCap: .round))

        // Large arc
        var arc3 = Path()
        arc3.addArc(center: center, radius: 10 * scale, startAngle: .degrees(-35), endAngle: .degrees(35), clockwise: false)
        context.stroke(arc3, with: .color(color.opacity(0.4)), style: StrokeStyle(lineWidth: 0.9 * scale / 1.1, lineCap: .round))
    }

    // MARK: - 發燒: 溫度計

    private func drawFever(context: GraphicsContext, scale: CGFloat) {
        // Tube
        let tube = CGRect(x: 9.5 * scale, y: 3 * scale, width: 3 * scale, height: 12 * scale)
        context.stroke(
            RoundedRectangle(cornerRadius: 1.5 * scale).path(in: tube),
            with: .color(color),
            lineWidth: 1.2 * scale / 1.1
        )

        // Bulb
        let bulbR: CGFloat = 2.5 * scale
        let bulbCenter = CGPoint(x: 11 * scale, y: 17 * scale)
        let bulbRect = CGRect(x: bulbCenter.x - bulbR, y: bulbCenter.y - bulbR, width: bulbR * 2, height: bulbR * 2)
        context.fill(Circle().path(in: bulbRect), with: .color(color.opacity(0.5)))

        // Mercury
        let mercury = CGRect(x: 10.2 * scale, y: 7 * scale, width: 1.6 * scale, height: 6 * scale)
        context.fill(
            RoundedRectangle(cornerRadius: 0.8 * scale).path(in: mercury),
            with: .color(color.opacity(0.5))
        )
    }

    // MARK: - 關節痛: 關節圓 + 骨線

    private func drawJoint(context: GraphicsContext, scale: CGFloat) {
        let center = CGPoint(x: 11 * scale, y: 11 * scale)
        let r: CGFloat = 2.5 * scale
        let circle = Circle().path(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        context.stroke(circle, with: .color(color), lineWidth: 1.3 * scale / 1.1)

        // Top bone
        var top = Path()
        top.move(to: CGPoint(x: 11 * scale, y: 4 * scale))
        top.addLine(to: CGPoint(x: 11 * scale, y: 8.5 * scale))
        context.stroke(top, with: .color(color), style: StrokeStyle(lineWidth: 1.5 * scale / 1.1, lineCap: .round))

        // Bottom bone
        var bottom = Path()
        bottom.move(to: CGPoint(x: 11 * scale, y: 13.5 * scale))
        bottom.addLine(to: CGPoint(x: 11 * scale, y: 18 * scale))
        context.stroke(bottom, with: .color(color), style: StrokeStyle(lineWidth: 1.5 * scale / 1.1, lineCap: .round))
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
        ForEach(SymptomType.allCases) { type in
            VStack(spacing: 4) {
                SymptomIconView(type: type, color: ZenColors.amber, size: 28)
                Text(type.displayName)
                    .font(.caption2)
            }
        }
    }
    .padding()
}
