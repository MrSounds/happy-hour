import Foundation
@preconcurrency import UserNotifications

@MainActor
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated static let weekdayUserInfoKey = "weekdayISO"

    typealias RouteHandler = @MainActor (Weekday) -> Void

    private var routeHandler: RouteHandler?

    override init() {
        super.init()
    }

    func install(
        on center: UNUserNotificationCenter = .current(),
        routeHandler: @escaping RouteHandler
    ) {
        self.routeHandler = routeHandler
        center.delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let weekdayISO = response.notification.request.content.userInfo[
            Self.weekdayUserInfoKey
        ] as? Int else {
            return
        }
        await route(to: weekdayISO)
    }

    func route(to weekdayISO: Int) {
        guard let weekday = Weekday(rawValue: weekdayISO) else { return }
        routeHandler?(weekday)
    }
}
