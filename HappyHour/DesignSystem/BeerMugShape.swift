import SwiftUI

/// The centered body of the beer mug. The handle is drawn as an overlay and
/// deliberately does not participate in layout, so it can overflow the screen.
struct BeerMugBodyShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let width = rect.width
        let height = rect.height
        let left = rect.minX
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY
        let shoulderY = top + height * 0.06
        let baseShoulderY = top + height * 0.90

        var path = Path()
        path.move(to: CGPoint(x: left + width * 0.10, y: top))
        path.addCurve(
            to: CGPoint(x: right - width * 0.10, y: top),
            control1: CGPoint(x: left + width * 0.30, y: top - height * 0.01),
            control2: CGPoint(x: right - width * 0.30, y: top - height * 0.01)
        )
        path.addCurve(
            to: CGPoint(x: right - width * 0.025, y: shoulderY),
            control1: CGPoint(x: right - width * 0.045, y: top),
            control2: CGPoint(x: right - width * 0.025, y: top + height * 0.025)
        )
        path.addLine(to: CGPoint(x: right - width * 0.045, y: baseShoulderY))
        path.addCurve(
            to: CGPoint(x: right - width * 0.10, y: bottom),
            control1: CGPoint(x: right - width * 0.04, y: bottom - height * 0.045),
            control2: CGPoint(x: right - width * 0.06, y: bottom)
        )
        path.addLine(to: CGPoint(x: left + width * 0.10, y: bottom))
        path.addCurve(
            to: CGPoint(x: left + width * 0.045, y: baseShoulderY),
            control1: CGPoint(x: left + width * 0.06, y: bottom),
            control2: CGPoint(x: left + width * 0.04, y: bottom - height * 0.045)
        )
        path.addLine(to: CGPoint(x: left + width * 0.025, y: shoulderY))
        path.addCurve(
            to: CGPoint(x: left + width * 0.10, y: top),
            control1: CGPoint(x: left + width * 0.025, y: top + height * 0.025),
            control2: CGPoint(x: left + width * 0.045, y: top)
        )
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> BeerMugBodyShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

/// A mask for the usable area above the heavy glass foot.
struct BeerMugInteriorShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + width * 0.035, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - width * 0.035, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - width * 0.055, y: rect.maxY - height * 0.035))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - width * 0.11, y: rect.maxY),
            control: CGPoint(x: rect.maxX - width * 0.06, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + width * 0.11, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.055, y: rect.maxY - height * 0.035),
            control: CGPoint(x: rect.minX + width * 0.06, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

/// The permanent foam crown. It is decorative and never communicates progress.
struct BeerFoamCrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + width * 0.02, y: rect.minY + height * 0.38))
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.34, y: rect.minY + height * 0.28),
            control1: CGPoint(x: rect.minX + width * 0.10, y: rect.minY + height * 0.08),
            control2: CGPoint(x: rect.minX + width * 0.22, y: rect.minY + height * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.62, y: rect.minY + height * 0.30),
            control1: CGPoint(x: rect.minX + width * 0.44, y: rect.minY + height * 0.40),
            control2: CGPoint(x: rect.minX + width * 0.52, y: rect.minY + height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - width * 0.02, y: rect.minY + height * 0.42),
            control1: CGPoint(x: rect.minX + width * 0.74, y: rect.minY + height * 0.50),
            control2: CGPoint(x: rect.minX + width * 0.88, y: rect.minY + height * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - width * 0.08, y: rect.minY + height * 0.68),
            control1: CGPoint(x: rect.maxX, y: rect.minY + height * 0.50),
            control2: CGPoint(x: rect.maxX - width * 0.02, y: rect.minY + height * 0.64)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.14, y: rect.minY + height * 0.72),
            control1: CGPoint(x: rect.minX + width * 0.72, y: rect.minY + height * 0.62),
            control2: CGPoint(x: rect.minX + width * 0.36, y: rect.minY + height * 0.80)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.055, y: rect.maxY),
            control1: CGPoint(x: rect.minX + width * 0.12, y: rect.minY + height * 0.76),
            control2: CGPoint(x: rect.minX + width * 0.10, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.02, y: rect.minY + height * 0.38),
            control1: CGPoint(x: rect.minX + width * 0.01, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + height * 0.54)
        )
        path.closeSubpath()
        return path
    }
}

struct BeerMugBaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.04, y: rect.minY),
            control1: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.20),
            control2: CGPoint(x: rect.maxX - rect.width * 0.28, y: rect.minY + rect.height * 0.20)
        )
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.07, y: rect.maxY - rect.height * 0.12))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.07, y: rect.maxY - rect.height * 0.12),
            control1: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.maxY),
            control2: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

/// A small, non-interactive preview used during onboarding.
struct BeerMugPreview: View {
    var body: some View {
        GeometryReader { proxy in
            let bodyWidth = proxy.size.width * 0.72
            let bodyHeight = proxy.size.height * 0.88
            let bodyX = proxy.size.width / 2
            let bodyY = proxy.size.height * 0.52
            let handleWidth = proxy.size.width * 0.40

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        HappyHourTheme.glassHighlight.opacity(0.55),
                        lineWidth: 10
                    )
                    .frame(width: handleWidth, height: bodyHeight * 0.56)
                    .position(
                        x: bodyX + bodyWidth * 0.50,
                        y: bodyY + bodyHeight * 0.02
                    )

                BeerMugBodyShape()
                    .fill(HappyHourTheme.glassFill.opacity(0.28))
                    .overlay {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: bodyHeight * 0.19)
                            ForEach(0..<5, id: \.self) { index in
                                HappyHourTheme.activityColor(at: index)
                            }
                        }
                        .clipShape(BeerMugInteriorShape())
                    }
                    .overlay {
                        BeerMugBodyShape()
                            .strokeBorder(
                                HappyHourTheme.glassHighlight.opacity(0.72),
                                lineWidth: 3
                            )
                    }
                    .frame(width: bodyWidth, height: bodyHeight)
                    .position(x: bodyX, y: bodyY)

                BeerFoamCrownShape()
                    .fill(HappyHourTheme.foam)
                    .frame(width: bodyWidth * 0.96, height: bodyHeight * 0.22)
                    .position(
                        x: bodyX,
                        y: bodyY - bodyHeight * 0.39
                    )
            }
        }
        .accessibilityHidden(true)
    }
}
