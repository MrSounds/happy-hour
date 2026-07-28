import SwiftUI

enum NotificationSettingsPresentationState: Equatable, Sendable {
    case notDetermined
    case enabled
    case provisional
    case denied

    var title: String {
        switch self {
        case .notDetermined:
            "Ikke valgt"
        case .enabled:
            "På"
        case .provisional:
            "Leveres stille"
        case .denied:
            "Av"
        }
    }

    var explanation: String {
        switch self {
        case .notDetermined:
            "Du har ikke valgt om Happy Hour kan sende startvarsler."
        case .enabled:
            "Du får et lokalt varsel når en planlagt Happy Hour starter."
        case .provisional:
            "Varslene kan leveres stille inntil du velger hvordan de skal vises."
        case .denied:
            "Varsler er slått av. Du kan aktivere dem i iPhone-innstillingene."
        }
    }

    var symbolName: String {
        switch self {
        case .notDetermined:
            "bell"
        case .enabled:
            "bell.badge"
        case .provisional:
            "bell.and.waves.left.and.right"
        case .denied:
            "bell.slash"
        }
    }
}

struct SettingsView: View {
    let notificationState: NotificationSettingsPresentationState
    let canRequestNotifications: Bool
    let onRequestNotifications: @MainActor () async -> Void
    let onOpenSystemSettings: () -> Void
    let onDone: () -> Void

    @State private var isRequestingNotifications = false

    var body: some View {
        NavigationStack {
            List {
                notificationSection
                privacySection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(HappyHourTheme.background)
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig", action: onDone)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("settings-done")
                }
            }
        }
        .happyHourScreenBackground()
        .accessibilityIdentifier("settings")
    }

    private var notificationSection: some View {
        Section {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: notificationState.symbolName)
                    .font(.title3)
                    .foregroundStyle(HappyHourTheme.sand)
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Startvarsler")
                            .font(.body.weight(.semibold))

                        Spacer()

                        Text(notificationState.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(notificationState.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 5)
            .accessibilityElement(children: .combine)

            switch notificationState {
            case .notDetermined:
                if canRequestNotifications {
                    Button {
                        guard !isRequestingNotifications else { return }
                        isRequestingNotifications = true
                        Task {
                            await onRequestNotifications()
                            isRequestingNotifications = false
                        }
                    } label: {
                        if isRequestingNotifications {
                            ProgressView()
                                .accessibilityLabel("Ber om varslingstillatelse")
                        } else {
                            Text("Slå på varsler")
                                .frame(minHeight: 44)
                        }
                    }
                    .disabled(isRequestingNotifications)
                    .accessibilityIdentifier("settings-enable-notifications")
                } else {
                    Text("Planlegg minst én dag før du slår på startvarsler.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .denied:
                Button(action: onOpenSystemSettings) {
                    Label("Åpne iPhone-innstillinger", systemImage: "arrow.up.forward.app")
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("open-system-settings")

            case .enabled, .provisional:
                EmptyView()
            }
        } header: {
            Text("Varsler")
        } footer: {
            Text(
                "Focus, Planlagt sammendrag og andre systemvalg kan forsinke "
                    + "eller skjule et varsel."
            )
        }
    }

    private var privacySection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lagres på denne iPhonen")
                        .font(.body.weight(.medium))
                    Text("Ukeplanen sendes ikke til Happy Hour eller en skytjeneste.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "iphone")
                    .foregroundStyle(HappyHourTheme.dustySage)
            }
            .padding(.vertical, 4)

            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kalender er en engangshandling")
                        .font(.body.weight(.medium))
                    Text(
                        "Hendelser synkroniseres ikke av appen. Kalenderen du velger "
                            + "kan likevel synkronisere via iCloud, Google eller Exchange."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(HappyHourTheme.blueGrey)
            }
            .padding(.vertical, 4)

            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingen appadministrert sikkerhetskopi")
                        .font(.body.weight(.medium))
                    Text(
                        "Hvis appen slettes, forsvinner planene med mindre de gjenopprettes "
                            + "som del av en sikkerhetskopi av iPhonen."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "externaldrive")
                    .foregroundStyle(HappyHourTheme.lavender)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Personvern")
        }
    }

    private var aboutSection: some View {
        Section("Om") {
            LabeledContent("Versjon", value: appVersion)
        }
    }

    private var appVersion: String {
        let shortVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        return switch (shortVersion, build) {
        case let (.some(version), .some(build)):
            "\(version) (\(build))"
        case let (.some(version), .none):
            version
        default:
            "–"
        }
    }
}
