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
        // CategoryBreakdown owns the ranking rule (total descending, ties by
        // name) so the digest's top category always agrees with Insights.
        let ranked = CategoryBreakdown.compute(
            expenses: trailing.map { (amount: $0.amountDollars, category: $0.categoryName) }
        )
        guard let top = ranked.first else { return nil }

        let total = trailing.reduce(0) { $0 + $1.amountDollars }
        let prior = expenses.filter { $0.timestamp > twoWeeksAgo && $0.timestamp <= weekAgo }
        let delta: Int? = prior.isEmpty ? nil : total - prior.reduce(0) { $0 + $1.amountDollars }

        return WeeklyDigest(
            totalDollars: total,
            topCategoryName: top.category,
            topCategoryDollars: top.total,
            deltaDollars: delta
        )
    }

    // MARK: - Wording

    public static let notificationTitle = "Your week in spending"

    public static func body(for digest: WeeklyDigest) -> String {
        let opening = "You spent \(digest.totalDollars.wholeDollars) this week, mostly on \(digest.topCategoryName)"
        guard let delta = digest.deltaDollars else {
            return opening + "."
        }
        if delta > 0 {
            return opening + " — up \(delta.wholeDollars) from last week."
        }
        if delta < 0 {
            return opening + " — down \((-delta).wholeDollars) from last week."
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
