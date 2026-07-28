import Foundation
@preconcurrency import UserNotifications

struct LocalNotificationDescriptor: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
    let weekdayISO: Int
    let foundationWeekday: Int
    let hour: Int
    let minute: Int

    func makeRequest() -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [AppNotificationDelegate.weekdayUserInfoKey: weekdayISO]

        let dateComponents = DateComponents(
            hour: hour,
            minute: minute,
            weekday: foundationWeekday
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
    }
}
