import EventKit
@preconcurrency import EventKitUI
import SwiftUI

enum CalendarEventEditResult: Equatable, Sendable {
    case saved
    case canceled
    case deleted
}

struct CalendarEventEditView: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    let onCompletion: @MainActor (CalendarEventEditResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ uiViewController: EKEventEditViewController,
        context: Context
    ) {}

    @MainActor
    final class Coordinator: NSObject, @preconcurrency EKEventEditViewDelegate {
        private let onCompletion: @MainActor (CalendarEventEditResult) -> Void

        init(onCompletion: @escaping @MainActor (CalendarEventEditResult) -> Void) {
            self.onCompletion = onCompletion
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            let result: CalendarEventEditResult
            switch action {
            case .saved:
                result = .saved
            case .deleted:
                result = .deleted
            case .canceled:
                result = .canceled
            @unknown default:
                result = .canceled
            }
            onCompletion(result)
        }
    }
}
