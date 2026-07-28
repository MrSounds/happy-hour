import SwiftUI

struct HappyHourPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 18)
            .foregroundStyle(HappyHourTheme.activityText)
            .background(
                Capsule()
                    .fill(
                        isEnabled
                            ? HappyHourTheme.primaryText
                            : HappyHourTheme.primaryText.opacity(0.35)
                    )
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
            .contentShape(Capsule())
    }
}

struct HappyHourSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 18)
            .foregroundStyle(HappyHourTheme.primaryText)
            .background(
                Capsule()
                    .stroke(HappyHourTheme.hairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.65 : (isEnabled ? 1 : 0.42))
            .contentShape(Capsule())
    }
}

struct HappyHourIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .foregroundStyle(HappyHourTheme.primaryText)
            .opacity(configuration.isPressed ? 0.54 : 1)
    }
}
