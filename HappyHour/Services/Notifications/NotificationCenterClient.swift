import Foundation
@preconcurrency import UserNotifications

enum AppNotificationAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    var permitsScheduling: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        }
    }
}

@MainActor
protocol NotificationCenterClient: AnyObject {
    func authorizationStatus() async -> AppNotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func pendingRequestIdentifiers() async -> Set<String>
    func add(_ descriptor: LocalNotificationDescriptor) async throws
    func removePendingRequests(withIdentifiers identifiers: [String])
}

@MainActor
final class SystemNotificationCenterClient: NotificationCenterClient {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> AppNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pendingRequestIdentifiers() async -> Set<String> {
        let requests = await center.pendingNotificationRequests()
        return Set(requests.map(\.identifier))
    }

    func add(_ descriptor: LocalNotificationDescriptor) async throws {
        try await center.add(descriptor.makeRequest())
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
