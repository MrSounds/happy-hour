import SwiftUI

enum HappyHourTheme {
    static let background = Color(
        red: 10.0 / 255.0,
        green: 10.0 / 255.0,
        blue: 11.0 / 255.0
    )
    static let primaryText = Color(
        red: 243.0 / 255.0,
        green: 240.0 / 255.0,
        blue: 234.0 / 255.0
    )
    static let activityText = Color(
        red: 17.0 / 255.0,
        green: 17.0 / 255.0,
        blue: 19.0 / 255.0
    )

    static let dustySage = Color(
        red: 127.0 / 255.0,
        green: 146.0 / 255.0,
        blue: 126.0 / 255.0
    )
    static let blueGrey = Color(
        red: 116.0 / 255.0,
        green: 133.0 / 255.0,
        blue: 145.0 / 255.0
    )
    static let lavender = Color(
        red: 149.0 / 255.0,
        green: 136.0 / 255.0,
        blue: 166.0 / 255.0
    )
    static let sand = Color(
        red: 176.0 / 255.0,
        green: 154.0 / 255.0,
        blue: 115.0 / 255.0
    )
    static let softTerracotta = Color(
        red: 169.0 / 255.0,
        green: 111.0 / 255.0,
        blue: 90.0 / 255.0
    )

    static let activityColors: [Color] = [
        dustySage,
        blueGrey,
        lavender,
        sand,
        softTerracotta
    ]

    static let secondaryText = primaryText.opacity(0.68)
    static let tertiaryText = primaryText.opacity(0.48)
    static let hairline = primaryText.opacity(0.18)
    static let raisedSurface = Color(
        red: 25.0 / 255.0,
        green: 25.0 / 255.0,
        blue: 28.0 / 255.0
    )
    static let selectedDay = Color(
        red: 184.0 / 255.0,
        green: 160.0 / 255.0,
        blue: 224.0 / 255.0
    )
    static let foam = Color(
        red: 244.0 / 255.0,
        green: 239.0 / 255.0,
        blue: 224.0 / 255.0
    )
    static let foamShadow = Color(
        red: 211.0 / 255.0,
        green: 201.0 / 255.0,
        blue: 179.0 / 255.0
    )
    static let foamBubble = Color.white
    static let glassFill = Color(
        red: 196.0 / 255.0,
        green: 187.0 / 255.0,
        blue: 172.0 / 255.0
    )
    static let glassHighlight = Color(
        red: 252.0 / 255.0,
        green: 247.0 / 255.0,
        blue: 235.0 / 255.0
    )
    static let glassShadow = Color(
        red: 55.0 / 255.0,
        green: 48.0 / 255.0,
        blue: 44.0 / 255.0
    )
    static let amberGlow = Color(
        red: 132.0 / 255.0,
        green: 87.0 / 255.0,
        blue: 42.0 / 255.0
    )

    static func activityColor(at index: Int) -> Color {
        activityColors[index.modulo(activityColors.count)]
    }

    static func activityColor(for token: ActivityColorToken) -> Color {
        switch token {
        case .dustySage:
            dustySage
        case .blueGrey:
            blueGrey
        case .lavender:
            lavender
        case .sand:
            sand
        case .softTerracotta:
            softTerracotta
        }
    }
}

private extension Int {
    func modulo(_ modulus: Int) -> Int {
        guard modulus > 0 else { return 0 }
        let remainder = self % modulus
        return remainder >= 0 ? remainder : remainder + modulus
    }
}

struct HappyHourScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(HappyHourTheme.primaryText)
            .tint(HappyHourTheme.primaryText)
            .background(HappyHourTheme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

extension View {
    func happyHourScreenBackground() -> some View {
        modifier(HappyHourScreenBackground())
    }
}
