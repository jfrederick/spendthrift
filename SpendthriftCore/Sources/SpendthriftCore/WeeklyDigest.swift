import Foundation

/// The Sunday-evening spending summary: trailing 7-day total, top category,
/// and week-over-week delta. Pure math + wording; scheduling lives in the
/// app target.
public struct WeeklyDigest: Equatable, Sendable {
    public let totalDollars: Int
    public let topCategoryName: String
    public let topCategoryDollars: Int
    /// Trailing week minus prior week; nil when the prior week has no data
    /// (first tracked week — no comparison to make).
    public let deltaDollars: Int?

    public init(totalDollars: Int, topCategoryName: String, topCategoryDollars: Int, deltaDollars: Int?) {
        self.totalDollars = totalDollars
        self.topCategoryName = topCategoryName
        self.topCategoryDollars = topCategoryDollars
        self.deltaDollars = deltaDollars
    }

    // MARK: - Computation

    /// Digest for the half-open trailing window (fireDate-7d, fireDate];
    /// the comparison window is the 7 days before that. Nil when the
    /// trailing window is empty — nothing to say beats a $0 notification.
    public static func compute(
        expenses: [(amountDollars: Int, categoryName: String, timestamp: Date)],
        fireDate: Date,
        calendar: Calendar
    ) -> WeeklyDigest? {
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: fireDate),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -7, to: weekAgo) else {
            return nil
        }

        let trailing = expenses.filter { $0.timestamp > weekAgo && $0.timestamp <= fireDate }
        guard !trailing.isEmpty else { return nil }

        var byCategory: [String: Int] = [:]
        for expense in trailing {
            byCategory[expense.categoryName, default: 0] += expense.amountDollars
        }
        // Ties break by name so the digest is deterministic.
        guard let top = byCategory.min(by: { ($1.value, $0.key) < ($0.value, $1.key) }) else {
            return nil
        }

        let total = trailing.reduce(0) { $0 + $1.amountDollars }
        let prior = expenses.filter { $0.timestamp > twoWeeksAgo && $0.timestamp <= weekAgo }
        let delta: Int? = prior.isEmpty ? nil : total - prior.reduce(0) { $0 + $1.amountDollars }

        return WeeklyDigest(
            totalDollars: total,
            topCategoryName: top.key,
            topCategoryDollars: top.value,
            deltaDollars: delta
        )
    }

    // MARK: - Wording

    public static let notificationTitle = "Your week in spending"

    public static func body(for digest: WeeklyDigest) -> String {
        let opening = "You spent $\(digest.totalDollars) this week, mostly on \(digest.topCategoryName)"
        guard let delta = digest.deltaDollars else {
            return opening + "."
        }
        if delta > 0 {
            return opening + " — up $\(delta) from last week."
        }
        if delta < 0 {
            return opening + " — down $\(-delta) from last week."
        }
        return opening + " — same as last week."
    }

    // MARK: - Scheduling instant

    /// The next Sunday at 18:00 in the given calendar's time zone, strictly
    /// after `now` (a Sunday at 17:59 schedules for that evening).
    public static func nextFireDate(after now: Date, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.weekday = 1 // Sunday in the Gregorian calendar
        components.hour = 18
        components.minute = 0
        components.second = 0
        return calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? now.addingTimeInterval(7 * 24 * 3600)
    }
}
