import SwiftUI

struct BeerMugFillMetrics: Equatable {
    static let fullSizeActivityCount = 5

    let activityCount: Int

    var slotCount: Int {
        max(Self.fullSizeActivityCount, activityCount)
    }

    var foamSlotCount: Int {
        max(Self.fullSizeActivityCount - activityCount, 0)
    }

    func rowHeight(in interiorHeight: CGFloat) -> CGFloat {
        guard interiorHeight > 0 else { return 0 }
        return interiorHeight / CGFloat(slotCount)
    }

    func foamHeight(in interiorHeight: CGFloat) -> CGFloat {
        rowHeight(in: interiorHeight) * CGFloat(foamSlotCount)
    }
}

struct ActivityBeerMugView: View {
    let activities: [ActivityModel]
    let onShowDetails: (ActivityModel) -> Void
    var emptyMessage: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var accessibilityContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        GeometryReader { proxy in
            mug(in: proxy.size)
        }
        .frame(maxWidth: .infinity)
        .frame(height: preferredHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Aktiviteter i ølglasset")
    }

    @ViewBuilder
    private func mug(in size: CGSize) -> some View {
        let bodyWidth = min(
            size.width * (dynamicTypeSize.isAccessibilitySize ? 0.86 : 0.80),
            dynamicTypeSize.isAccessibilitySize ? 460 : 390
        )
        let bodyHeight = size.height * 0.94
        let bodyFrame = CGRect(
            x: (size.width - bodyWidth) / 2,
            y: size.height * 0.025,
            width: bodyWidth,
            height: bodyHeight
        )
        let crownHeight = bodyHeight * 0.17
        let baseHeight = bodyHeight * 0.095
        let fillFrame = CGRect(
            x: bodyFrame.minX + bodyWidth * 0.04,
            y: bodyFrame.minY + crownHeight * 1.04,
            width: bodyWidth * 0.92,
            height: bodyHeight - crownHeight * 1.04 - baseHeight * 1.10
        )

        ZStack {
            mugGlow(bodyFrame: bodyFrame)
            mugHandle(bodyFrame: bodyFrame)
            mugBodyBackground(bodyFrame: bodyFrame)
            foamBacking(bodyFrame: bodyFrame, crownHeight: crownHeight)
            fillContent(frame: fillFrame)
            glassTexture(bodyFrame: bodyFrame)
            mugBase(bodyFrame: bodyFrame, baseHeight: baseHeight)
            foamCrown(bodyFrame: bodyFrame, crownHeight: crownHeight)
            mugOutline(bodyFrame: bodyFrame)
        }
    }

    private func mugGlow(bodyFrame: CGRect) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        HappyHourTheme.amberGlow.opacity(reduceTransparency ? 0.12 : 0.42),
                        HappyHourTheme.amberGlow.opacity(reduceTransparency ? 0.05 : 0.16),
                        .clear
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: bodyFrame.width * 0.82
                )
            )
            .frame(
                width: bodyFrame.width * 1.85,
                height: bodyFrame.height * 0.96
            )
            .position(x: bodyFrame.midX, y: bodyFrame.midY)
            .blur(radius: reduceTransparency ? 8 : 22)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func mugHandle(bodyFrame: CGRect) -> some View {
        let handleWidth = bodyFrame.width * 0.72
        let handleHeight = bodyFrame.height * 0.61
        let centerX = bodyFrame.maxX + handleWidth * 0.28
        let centerY = bodyFrame.minY + bodyFrame.height * 0.54
        let lineWidth = max(18, bodyFrame.width * 0.075)

        return ZStack {
            RoundedRectangle(
                cornerRadius: min(handleWidth, handleHeight) * 0.24,
                style: .continuous
            )
            .stroke(
                HappyHourTheme.amberGlow.opacity(reduceTransparency ? 0.06 : 0.20),
                lineWidth: lineWidth * 1.55
            )
            .blur(radius: reduceTransparency ? 2 : 12)

            RoundedRectangle(
                cornerRadius: min(handleWidth, handleHeight) * 0.24,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        HappyHourTheme.glassHighlight.opacity(0.72),
                        HappyHourTheme.glassFill.opacity(0.30),
                        HappyHourTheme.glassShadow.opacity(0.72),
                        HappyHourTheme.glassHighlight.opacity(0.58)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: lineWidth
            )

            RoundedRectangle(
                cornerRadius: min(handleWidth, handleHeight) * 0.24,
                style: .continuous
            )
            .stroke(
                HappyHourTheme.glassHighlight.opacity(
                    reduceTransparency ? 0.62 : 0.34
                ),
                lineWidth: 2
            )
        }
        .frame(width: handleWidth, height: handleHeight)
        .position(x: centerX, y: centerY)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mugBodyBackground(bodyFrame: CGRect) -> some View {
        BeerMugBodyShape()
            .fill(
                LinearGradient(
                    colors: [
                        HappyHourTheme.glassHighlight.opacity(
                            reduceTransparency ? 0.22 : 0.14
                        ),
                        HappyHourTheme.glassFill.opacity(
                            reduceTransparency ? 0.24 : 0.08
                        ),
                        HappyHourTheme.glassShadow.opacity(
                            reduceTransparency ? 0.30 : 0.16
                        )
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: bodyFrame.width, height: bodyFrame.height)
            .position(x: bodyFrame.midX, y: bodyFrame.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func foamBacking(
        bodyFrame: CGRect,
        crownHeight: CGFloat
    ) -> some View {
        BeerFoamFill()
            .frame(
                width: bodyFrame.width * 0.92,
                height: crownHeight * 0.58
            )
            .position(
                x: bodyFrame.midX,
                y: bodyFrame.minY + crownHeight * 0.78
            )
            .clipShape(BeerMugBodyShape())
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func fillContent(frame: CGRect) -> some View {
        let metrics = BeerMugFillMetrics(activityCount: activities.count)
        let rowHeight = metrics.rowHeight(in: frame.height)
        let foamHeight = metrics.foamHeight(in: frame.height)

        return VStack(spacing: 0) {
            BeerFoamFill()
                .frame(height: foamHeight)
                .accessibilityHidden(true)

            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                activityRow(
                    activity,
                    index: index,
                    height: rowHeight
                )
            }
        }
        .overlay {
            if activities.isEmpty, let emptyMessage {
                Text(emptyMessage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(HappyHourTheme.activityText.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
        .frame(width: frame.width, height: frame.height, alignment: .bottom)
        .clipShape(BeerMugInteriorShape())
        .position(x: frame.midX, y: frame.midY)
    }

    private func activityRow(
        _ activity: ActivityModel,
        index: Int,
        height: CGFloat
    ) -> some View {
        Button {
            onShowDetails(activity)
        } label: {
            HStack(spacing: 8) {
                Text(activity.name)
                    .font(rowFont)
                    .foregroundStyle(HappyHourTheme.activityText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(HappyHourTheme.activityText.opacity(0.76))
                    .frame(width: 28)
                    .accessibilityHidden(true)
            }
            .padding(.leading, activities.count >= 8 ? 18 : 24)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        HappyHourTheme.activityColor(for: activity.colorToken)
                            .opacity(reduceTransparency ? 1 : 0.92),
                        HappyHourTheme.activityColor(for: activity.colorToken),
                        HappyHourTheme.activityColor(for: activity.colorToken)
                            .opacity(reduceTransparency ? 1 : 0.86)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(HappyHourTheme.activityText.opacity(0.12))
                    .frame(height: 0.5)
            }
            .overlay {
                if accessibilityContrast == .increased || differentiateWithoutColor {
                    Rectangle()
                        .stroke(HappyHourTheme.activityText.opacity(0.72), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: height)
        .contentShape(Rectangle())
        .accessibilityLabel("Vis detaljer for \(activity.name)")
        .accessibilityValue("Aktivitet \(index + 1) av \(activities.count)")
        .accessibilityHint(
            (activity.details ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
                ? "Ingen notater er lagt til"
                : "Notater er tilgjengelige"
        )
        .accessibilityIdentifier("activity-\(index)")
    }

    private var rowFont: Font {
        if dynamicTypeSize.isAccessibilitySize {
            return .body.weight(.semibold)
        }
        if activities.count >= 8 {
            return .subheadline.weight(.semibold)
        }
        if activities.count >= 6 {
            return .body.weight(.semibold)
        }
        return .title3.weight(.semibold)
    }

    private func glassTexture(bodyFrame: CGRect) -> some View {
        BeerMugGlassTexture(reduceTransparency: reduceTransparency)
            .frame(width: bodyFrame.width, height: bodyFrame.height)
            .clipShape(BeerMugBodyShape())
            .position(x: bodyFrame.midX, y: bodyFrame.midY)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func mugBase(
        bodyFrame: CGRect,
        baseHeight: CGFloat
    ) -> some View {
        BeerMugBaseShape()
            .fill(
                LinearGradient(
                    colors: [
                        HappyHourTheme.glassHighlight.opacity(0.38),
                        HappyHourTheme.glassShadow.opacity(0.52),
                        HappyHourTheme.glassHighlight.opacity(0.44)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                BeerMugBaseShape()
                    .stroke(
                        HappyHourTheme.glassHighlight.opacity(0.44),
                        lineWidth: 2
                    )
            }
            .frame(width: bodyFrame.width, height: baseHeight * 1.22)
            .position(
                x: bodyFrame.midX,
                y: bodyFrame.maxY - baseHeight * 0.49
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func foamCrown(
        bodyFrame: CGRect,
        crownHeight: CGFloat
    ) -> some View {
        BeerFoamCrown()
            .frame(width: bodyFrame.width * 0.98, height: crownHeight * 1.14)
            .position(
                x: bodyFrame.midX,
                y: bodyFrame.minY + crownHeight * 0.46
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func mugOutline(bodyFrame: CGRect) -> some View {
        ZStack {
            BeerMugBodyShape()
                .strokeBorder(
                    HappyHourTheme.glassShadow.opacity(0.68),
                    lineWidth: 8
                )
                .blur(radius: 1.2)

            BeerMugBodyShape()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            HappyHourTheme.glassHighlight.opacity(0.86),
                            HappyHourTheme.glassHighlight.opacity(0.36),
                            HappyHourTheme.glassShadow.opacity(0.62),
                            HappyHourTheme.glassHighlight.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        }
        .frame(width: bodyFrame.width, height: bodyFrame.height)
        .position(x: bodyFrame.midX, y: bodyFrame.midY)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var preferredHeight: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            let activityHeight = CGFloat(max(activities.count, 5)) * 68
            return max(760, activityHeight + 215)
        }
        return 660
    }
}

private struct BeerFoamFill: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    HappyHourTheme.foam,
                    HappyHourTheme.foamShadow,
                    HappyHourTheme.foam.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            FoamBubbleTexture(opacity: 0.18)
        }
    }
}

private struct BeerFoamCrown: View {
    var body: some View {
        BeerFoamCrownShape()
            .fill(
                LinearGradient(
                    colors: [
                        HappyHourTheme.foam,
                        HappyHourTheme.foam.opacity(0.98),
                        HappyHourTheme.foamShadow
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                FoamBubbleTexture(opacity: 0.22)
                    .mask(BeerFoamCrownShape())
            }
            .overlay {
                BeerFoamCrownShape()
                    .stroke(HappyHourTheme.foamShadow.opacity(0.50), lineWidth: 1.5)
            }
            .shadow(
                color: HappyHourTheme.foam.opacity(0.18),
                radius: 8,
                y: 2
            )
    }
}

private struct FoamBubbleTexture: View {
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            for index in 0..<128 {
                let x = CGFloat((index * 37 + 11) % 101) / 100 * size.width
                let y = CGFloat((index * 53 + 7) % 97) / 96 * size.height
                let diameter = CGFloat(1 + (index * 7) % 8)
                let bubble = Path(
                    ellipseIn: CGRect(
                        x: x - diameter / 2,
                        y: y - diameter / 2,
                        width: diameter,
                        height: diameter
                    )
                )
                context.stroke(
                    bubble,
                    with: .color(HappyHourTheme.foamBubble.opacity(opacity)),
                    lineWidth: max(0.5, diameter * 0.10)
                )
                if index.isMultiple(of: 4) {
                    context.fill(
                        bubble,
                        with: .color(
                            HappyHourTheme.foamShadow.opacity(opacity * 0.30)
                        )
                    )
                }
            }
        }
    }
}

private struct BeerMugGlassTexture: View {
    let reduceTransparency: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(
                        cornerRadius: proxy.size.width * 0.08,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                HappyHourTheme.glassHighlight.opacity(
                                    reduceTransparency ? 0.16 : 0.26
                                ),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: proxy.size.width * 0.17,
                        height: proxy.size.height * 0.82
                    )
                    .position(
                        x: proxy.size.width
                            * (0.12 + CGFloat(index) * 0.152),
                        y: proxy.size.height * 0.56
                    )
                }

                Canvas { context, size in
                    guard !reduceTransparency else { return }
                    for index in 0..<74 {
                        let x = CGFloat((index * 47 + 5) % 103) / 102 * size.width
                        let y = CGFloat((index * 31 + 19) % 107) / 106 * size.height
                        let diameter = CGFloat(1 + (index * 5) % 4)
                        let speck = Path(
                            ellipseIn: CGRect(
                                x: x,
                                y: y,
                                width: diameter,
                                height: diameter
                            )
                        )
                        context.fill(
                            speck,
                            with: .color(
                                HappyHourTheme.glassHighlight.opacity(0.12)
                            )
                        )
                    }
                }

                LinearGradient(
                    colors: [
                        HappyHourTheme.glassShadow.opacity(0.28),
                        .clear,
                        .clear,
                        HappyHourTheme.glassHighlight.opacity(0.16),
                        .clear,
                        HappyHourTheme.glassShadow.opacity(0.30)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
}
