import SwiftData
import SwiftUI

@main
@MainActor
struct HappyHourApp: App {
    @State private var appModel: AppModel?
    private let startupError: String?

    init() {
        do {
            let arguments = ProcessInfo.processInfo.arguments
            let isUITesting = arguments.contains("-uiTesting")
            let container = try HappyHourPersistence.makeContainer(
                inMemory: isUITesting
            )
            let preferences: UserDefaults
            if isUITesting {
                preferences = UserDefaults(
                    suiteName: "HappyHourUITests-\(UUID().uuidString)"
                ) ?? .standard
            } else {
                preferences = .standard
            }

            _appModel = State(
                initialValue: AppModel(
                    modelContainer: container,
                    preferences: preferences,
                    configuredFixture: arguments.contains("-configuredFixture"),
                    beerMugFixture: arguments.contains("-beerMugFixture")
                )
            )
            startupError = nil
        } catch {
            _appModel = State(initialValue: nil)
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let appModel {
                RootView(model: appModel)
            } else {
                StartupFailureView(
                    message: startupError ?? "Lagringen kunne ikke åpnes."
                )
            }
        }
    }
}

private struct StartupFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(HappyHourTheme.sand)

            Text("Happy Hour kunne ikke starte")
                .font(.title2.weight(.semibold))

            Text(message)
                .foregroundStyle(HappyHourTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .happyHourScreenBackground()
    }
}
