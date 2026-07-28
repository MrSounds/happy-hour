import SwiftUI
import UIKit

/// Preserves a transactional editor draft and turns a pull-to-dismiss attempt
/// into the same discard confirmation used by the Cancel button.
struct InteractiveDismissGuard: UIViewControllerRepresentable {
    let isDisabled: Bool
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> ObserverViewController {
        let controller = ObserverViewController()
        controller.isDisabled = isDisabled
        controller.onAttempt = onAttempt
        return controller
    }

    func updateUIViewController(
        _ uiViewController: ObserverViewController,
        context: Context
    ) {
        uiViewController.isDisabled = isDisabled
        uiViewController.onAttempt = onAttempt
        uiViewController.installPresentationDelegate()
    }

    @MainActor
    final class ObserverViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
        var isDisabled = false
        var onAttempt: (() -> Void)?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installPresentationDelegate()
        }

        func installPresentationDelegate() {
            var hostingController = parent
            while let nextParent = hostingController?.parent {
                hostingController = nextParent
            }
            hostingController?.presentationController?.delegate = self
        }

        func presentationControllerShouldDismiss(
            _ presentationController: UIPresentationController
        ) -> Bool {
            !isDisabled
        }

        func presentationControllerDidAttemptToDismiss(
            _ presentationController: UIPresentationController
        ) {
            guard isDisabled else { return }
            onAttempt?()
        }
    }
}
