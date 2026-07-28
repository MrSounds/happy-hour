import Foundation

struct NotificationReconciliationResult: Equatable, Sendable {
    let authorizationStatus: AppNotificationAuthorizationStatus
    let scheduledIdentifiers: [String]
    let removedIdentifiers: [String]
}

@MainActor
final class NotificationScheduler {
    nonisolated static let identifierPrefix = "happyhour.start.iso-"

    private let client: any NotificationCenterClient

    init(client: any NotificationCenterClient = SystemNotificationCenterClient()) {
        self.client = client
    }

    func authorizationStatus() async -> AppNotificationAuthorizationStatus {
        await client.authorizationStatus()
    }

    @discardableResult
    func requestAuthorization() async throws -> Bool {
        try await client.requestAuthorization()
    }

    /// Replaces this app's weekly requests with a deterministic desired set.
    /// Requests belonging to other features or apps are never removed.
    func reconcile(
        _ schedules: [DayPlanSnapshot]
    ) async throws -> NotificationReconciliationResult {
        let status = await client.authorizationStatus()
        let pending = await client.pendingRequestIdentifiers()
        let managedPending = pending
            .filter { $0.hasPrefix(Self.identifierPrefix) }
            .sorted()

        guard status.permitsScheduling else {
            if !managedPending.isEmpty {
                client.removePendingRequests(withIdentifiers: managedPending)
            }
            return NotificationReconciliationResult(
                authorizationStatus: status,
                scheduledIdentifiers: [],
                removedIdentifiers: managedPending
            )
        }

        let desired = schedules
            .filter(\.isConfigured)
            .sorted { $0.weekday.isoWeekday < $1.weekday.isoWeekday }
            .map(Self.descriptor(for:))

        // Adding a request with the same stable identifier replaces it. Add the
        // complete desired set before removing stale weekdays so a transient add
        // failure never destroys otherwise valid existing reminders.
        for descriptor in desired {
            try await client.add(descriptor)
        }

        let desiredIdentifiers = Set(desired.map(\.identifier))
        let staleIdentifiers = managedPending
            .filter { !desiredIdentifiers.contains($0) }
        if !staleIdentifiers.isEmpty {
            client.removePendingRequests(withIdentifiers: staleIdentifiers)
        }

        return NotificationReconciliationResult(
            authorizationStatus: status,
            scheduledIdentifiers: desired.map(\.identifier),
            removedIdentifiers: staleIdentifiers
        )
    }

    nonisolated static func descriptor(
        for schedule: DayPlanSnapshot
    ) -> LocalNotificationDescriptor {
        let names = schedule.activities
            .map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let shownNames = names.prefix(3).joined(separator: ", ")
        let remainder = max(0, names.count - 3)

        let body: String
        if shownNames.isEmpty {
            body = "Tid for din planlagte Happy Hour."
        } else if remainder == 0 {
            body = shownNames
        } else {
            body = "\(shownNames) og \(remainder) til"
        }

        return LocalNotificationDescriptor(
            identifier: identifier(for: schedule.weekday),
            title: "Din Happy Hour starter nå",
            body: body,
            weekdayISO: schedule.weekday.isoWeekday,
            foundationWeekday: schedule.weekday.foundationWeekday,
            hour: schedule.startMinuteOfDay / 60,
            minute: schedule.startMinuteOfDay % 60
        )
    }

    nonisolated static func identifier(for weekday: Weekday) -> String {
        "\(identifierPrefix)\(weekday.isoWeekday)"
    }
}
