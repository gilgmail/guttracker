import SwiftUI

/// 抽象幾何 Bristol 圖形 — 取代 emoji
struct BristolShapeView: View {
    let type: Int
    var color: Color = .secondary
    var size: CGFloat = 28

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width
            let scale = s / 28  // reference viewBox is 28×28

            switch type {
            case 1: drawType1(context: context, scale: scale)
            case 2: drawType2(context: context, scale: scale)
            case 3: drawType3(context: context, scale: scale)
            case 4: drawType4(context: context, scale: scale)
            case 5: drawType5(context: context, scale: scale)
            case 6: drawType6(context: context, scale: scale)
            case 7: drawType7(context: context, scale: scale)
            default: break
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Type 1: 散落硬塊

    private func drawType1(context: GraphicsContext, scale: CGFloat) {
        let circles: [(cx: CGFloat, cy: CGFloat, r: CGFloat, op: CGFloat)] = [
            (8, 10, 3.5, 0.9),
            (18, 8, 3.0, 0.7),
            (13, 17, 3.2, 0.8),
            (21, 16, 2.5, 0.6),
        ]
        for c in circles {
            let rect = CGRect(
                x: (c.cx - c.r) * scale,
                y: (c.cy - c.r) * scale,
                width: c.r * 2 * scale,
                height: c.r * 2 * scale
            )
            context.fill(Circle().path(in: rect), with: .color(color.opacity(c.op)))
        }
    }

    // MARK: - Type 2: 塊狀香腸

    private func drawType2(context: GraphicsContext, scale: CGFloat) {
        // Base rounded rect
        let rect = CGRect(x: 4 * scale, y: 10 * scale, width: 20 * scale, height: 8 * scale)
        context.fill(
            RoundedRectangle(cornerRadius: 4 * scale).path(in: rect),
            with: .color(color.opacity(0.5))
        )
        // Bumps
        let bumps: [(cx: CGFloat, cy: CGFloat, r: CGFloat, op: CGFloat)] = [
            (9, 14, 2.8, 0.8),
            (16, 14, 2.5, 0.8),
            (22, 14, 2.0, 0.7),
        ]
        for b in bumps {
            let r = CGRect(
                x: (b.cx - b.r) * scale,
                y: (b.cy - b.r) * scale,
                width: b.r * 2 * scale,
                height: b.r * 2 * scale
            )
            context.fill(Circle().path(in: r), with: .color(color.opacity(b.op)))
        }
    }

    // MARK: - Type 3: 裂紋香腸

    private func drawType3(context: GraphicsContext, scale: CGFloat) {
        let rect = CGRect(x: 3 * scale, y: 10 * scale, width: 22 * scale, height: 8 * scale)
        context.fill(
            RoundedRectangle(cornerRadius: 4 * scale).path(in: rect),
            with: .color(color.opacity(0.7))
        )
        // Crack lines
        let crackColor = Color(white: 0.05)
        var crack1 = Path()
        crack1.move(to: CGPoint(x: 10 * scale, y: 10 * scale))
        crack1.addLine(to: CGPoint(x: 11 * scale, y: 14 * scale))
        context.stroke(crack1, with: .color(crackColor.opacity(0.5)), lineWidth: 1 * scale / 1.2)

        var crack2 = Path()
        crack2.move(to: CGPoint(x: 16 * scale, y: 10 * scale))
        crack2.addLine(to: CGPoint(x: 15 * scale, y: 14 * scale))
        context.stroke(crack2, with: .color(crackColor.opacity(0.5)), lineWidth: 1 * scale / 1.2)
    }

    // MARK: - Type 4: 光滑條狀

    private func drawType4(context: GraphicsContext, scale: CGFloat) {
        let rect = CGRect(x: 3 * scale, y: 11 * scale, width: 22 * scale, height: 7 * scale)
        context.fill(
            RoundedRectangle(cornerRadius: 3.5 * scale).path(in: rect),
            with: .color(color.opacity(0.8))
        )
    }

    // MARK: - Type 5: 軟塊

    private func drawType5(context: GraphicsContext, scale: CGFloat) {
        let ellipses: [(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, op: CGFloat)] = [
            (8, 14, 5, 4, 0.6),
            (19, 13, 5.5, 4.5, 0.55),
        ]
        for e in ellipses {
            let rect = CGRect(
                x: (e.cx - e.rx) * scale,
                y: (e.cy - e.ry) * scale,
                width: e.rx * 2 * scale,
                height: e.ry * 2 * scale
            )
            context.fill(Ellipse().path(in: rect), with: .color(color.opacity(e.op)))
        }
    }

    // MARK: - Type 6: 糊狀 blob

    private func drawType6(context: GraphicsContext, scale: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: 4 * scale, y: 16 * scale))
        path.addQuadCurve(
            to: CGPoint(x: 10 * scale, y: 13 * scale),
            control: CGPoint(x: 6 * scale, y: 9 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 17 * scale, y: 12 * scale),
            control: CGPoint(x: 13 * scale, y: 8 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 24 * scale, y: 14 * scale),
            control: CGPoint(x: 20 * scale, y: 9 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 18 * scale, y: 17 * scale),
            control: CGPoint(x: 22 * scale, y: 19 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 10 * scale, y: 17 * scale),
            control: CGPoint(x: 14 * scale, y: 20 * scale)
        )
        path.addQuadCurve(
            to: CGPoint(x: 4 * scale, y: 16 * scale),
            control: CGPoint(x: 7 * scale, y: 19 * scale)
        )
        path.closeSubpath()
        context.fill(path, with: .color(color.opacity(0.5)))
    }

    // MARK: - Type 7: 水狀

    private func drawType7(context: GraphicsContext, scale: CGFloat) {
        // Flat puddle
        let puddle = CGRect(
            x: (14 - 9) * scale,
            y: (16 - 5) * scale,
            width: 18 * scale,
            height: 10 * scale
        )
        context.fill(Ellipse().path(in: puddle), with: .color(color.opacity(0.3)))
        // Droplets
        let drops: [(cx: CGFloat, cy: CGFloat, r: CGFloat, op: CGFloat)] = [
            (10, 11, 1.5, 0.6),
            (16, 9, 1.2, 0.5),
            (13, 14, 1.0, 0.4),
        ]
        for d in drops {
            let rect = CGRect(
                x: (d.cx - d.r) * scale,
                y: (d.cy - d.r) * scale,
                width: d.r * 2 * scale,
                height: d.r * 2 * scale
            )
            context.fill(Circle().path(in: rect), with: .color(color.opacity(d.op)))
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(1...7, id: \.self) { type in
            VStack(spacing: 4) {
                BristolShapeView(
                    type: type,
                    color: ZenColors.bristolZone(for: type),
                    size: 32
                )
                Text("\(type)")
                    .font(.caption2)
            }
        }
    }
    .padding()
}
