import SwiftUI

struct OnboardingView: View {
    let today: Weekday
    let onCreateFirstPlan: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 28)

                onboardingBeerMug

                VStack(spacing: 12) {
                    Text("En time som er din")
                        .font(.largeTitle.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text(
                        "Fyll din Happy Hour med det som gjør deg glad, rolig eller mer deg selv. "
                            + "Uken lagres bare på denne iPhonen."
                    )
                    .font(.body)
                    .foregroundStyle(HappyHourTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    Button(
                        "Planlegg \(today.happyHourDisplayName.lowercased())",
                        action: onCreateFirstPlan
                    )
                    .buttonStyle(HappyHourPrimaryButtonStyle())
                    .accessibilityHint("Åpner redigeringen for din første Happy Hour")
                    .accessibilityIdentifier("onboarding-create-plan")

                    Button("Hopp over", action: onSkip)
                        .frame(minWidth: 88, minHeight: 44)
                        .foregroundStyle(HappyHourTheme.secondaryText)
                        .accessibilityHint("Du kan planlegge en dag senere")
                        .accessibilityIdentifier("onboarding-skip")
                }

                Text("Ingen konto. Ingen nettsky. Ingen streaks.")
                    .font(.footnote)
                    .foregroundStyle(HappyHourTheme.tertiaryText)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 18)
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .happyHourScreenBackground()
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }

            withAnimation(.easeOut(duration: 0.55)) {
                hasAppeared = true
            }
        }
        .accessibilityIdentifier("onboarding")
    }

    private var onboardingBeerMug: some View {
        BeerMugPreview()
        .frame(width: 230, height: 250)
        .scaleEffect(hasAppeared ? 1 : 0.96)
        .opacity(hasAppeared ? 1 : 0)
        .accessibilityHidden(true)
    }
}

struct NotificationPermissionPrimerView: View {
    let onEnable: @MainActor () async -> Void
    let onNotNow: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(HappyHourTheme.sand)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(HappyHourTheme.sand.opacity(0.12))
                )
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Et rolig lite vink")
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(
                    "Happy Hour kan varsle deg når dagens tid starter. "
                        + "Du kan endre dette når som helst i Innstillinger."
                )
                .font(.body)
                .foregroundStyle(HappyHourTheme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    guard !isRequesting else { return }
                    isRequesting = true
                    Task {
                        await onEnable()
                        isRequesting = false
                    }
                } label: {
                    if isRequesting {
                        ProgressView()
                            .accessibilityLabel("Ber om varslingstillatelse")
                    } else {
                        Text("Slå på varsler")
                    }
                }
                .buttonStyle(HappyHourPrimaryButtonStyle())
                .disabled(isRequesting)
                .accessibilityIdentifier("enable-notifications")

                Button("Ikke nå", action: onNotNow)
                    .frame(minWidth: 88, minHeight: 44)
                    .foregroundStyle(HappyHourTheme.secondaryText)
                    .disabled(isRequesting)
                    .accessibilityIdentifier("skip-notifications")
            }
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .happyHourScreenBackground()
        .accessibilityIdentifier("notification-primer")
    }
}
