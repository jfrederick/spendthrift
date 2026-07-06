import Foundation
import SwiftData
import UserNotifications
import SpendthriftCore

/// Schedules the Sunday-evening digest as a local notification. Content is
/// fixed at scheduling time, so `refresh` is called wherever the app
/// process gains fresh data (foreground, in-app save, voice-intent save)
/// and replaces the pending request via its stable identifier (design D3).
@MainActor
enum DigestScheduler {
    static let requestIdentifier = "weekly-digest"

    /// The digest that a refresh right now would schedule, or nil when the
    /// trailing week is empty. Factored out so tests exercise the real
    /// content pipeline without UserNotifications.
    static func upcomingDigest(
        store: ExpenseStore,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (digest: WeeklyDigest, fireDate: Date)? {
        let fireDate = WeeklyDigest.nextFireDate(after: now, calendar: calendar)
        let items = ((try? store.allExpenses()) ?? []).map { expense in
            (
                amountDollars: expense.amountDollars,
                categoryName: expense.category?.name ?? CategoryRules.fallbackCategoryName,
                timestamp: expense.timestamp
            )
        }
        guard let digest = WeeklyDigest.compute(expenses: items, fireDate: fireDate, calendar: calendar) else {
            return nil
        }
        return (digest, fireDate)
    }

    /// Recomputes and replaces the pending digest; removes it when the
    /// feature is off or there is nothing to say (design D5).
    static func refresh(store: ExpenseStore, now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        guard DigestPreferences.isEnabled, let upcoming = upcomingDigest(store: store, now: now) else {
            center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = WeeklyDigest.notificationTitle
        content.body = WeeklyDigest.body(for: upcoming.digest)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: upcoming.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger))
    }

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}
