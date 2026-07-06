import Foundation
import Testing
@testable import SpendthriftCore

@Suite("WeeklyDigest")
struct WeeklyDigestTests {
    static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func date(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        guard let d = f.date(from: iso) else { fatalError("bad date \(iso)") }
        return d
    }

    /// Sunday 2024-01-21 18:00 UTC.
    static let fire = date("2024-01-21T18:00:00Z")

    typealias Item = (amountDollars: Int, categoryName: String, timestamp: Date)

    // MARK: - compute

    @Test("normal week with prior data")
    func normalWeek() {
        let expenses: [Item] = [
            (120, "Food & Drink", Self.date("2024-01-18T12:00:00Z")),
            (94, "Transport", Self.date("2024-01-16T12:00:00Z")),
            (246, "Rent", Self.date("2024-01-10T12:00:00Z")),
        ]
        let digest = WeeklyDigest.compute(expenses: expenses, fireDate: Self.fire, calendar: Self.utc)
        #expect(digest?.totalDollars == 214)
        #expect(digest?.topCategoryName == "Food & Drink")
        #expect(digest?.topCategoryDollars == 120)
        #expect(digest?.deltaDollars == -32)
    }

    @Test("first tracked week has no comparison")
    func firstWeek() {
        let expenses: [Item] = [(50, "Groceries", Self.date("2024-01-20T12:00:00Z"))]
        let digest = WeeklyDigest.compute(expenses: expenses, fireDate: Self.fire, calendar: Self.utc)
        #expect(digest?.totalDollars == 50)
        #expect(digest?.deltaDollars == nil)
    }

    @Test("empty trailing week produces nil")
    func emptyWeek() {
        let expenses: [Item] = [(246, "Rent", Self.date("2024-01-10T12:00:00Z"))]
        #expect(WeeklyDigest.compute(expenses: expenses, fireDate: Self.fire, calendar: Self.utc) == nil)
        #expect(WeeklyDigest.compute(expenses: [], fireDate: Self.fire, calendar: Self.utc) == nil)
    }

    @Test("half-open window boundaries: (fire-7d, fire]")
    func windowBoundaries() {
        let expenses: [Item] = [
            // Exactly 7 days before fire -> prior window.
            (10, "Transport", Self.date("2024-01-14T18:00:00Z")),
            // Exactly at fire -> trailing window.
            (25, "Food & Drink", Self.fire),
        ]
        let digest = WeeklyDigest.compute(expenses: expenses, fireDate: Self.fire, calendar: Self.utc)
        #expect(digest?.totalDollars == 25)
        #expect(digest?.deltaDollars == 15)
    }

    @Test("top category tie broken by name")
    func topCategoryTie() {
        let expenses: [Item] = [
            (40, "Transport", Self.date("2024-01-19T12:00:00Z")),
            (40, "Food & Drink", Self.date("2024-01-18T12:00:00Z")),
        ]
        let digest = WeeklyDigest.compute(expenses: expenses, fireDate: Self.fire, calendar: Self.utc)
        #expect(digest?.topCategoryName == "Food & Drink")
    }

    // MARK: - wording

    @Test("down week body")
    func downBody() {
        let digest = WeeklyDigest(totalDollars: 214, topCategoryName: "Food & Drink", topCategoryDollars: 120, deltaDollars: -32)
        let body = WeeklyDigest.body(for: digest)
        #expect(body.contains("$214"))
        #expect(body.contains("Food & Drink"))
        #expect(body.contains("down $32"))
    }

    @Test("up week body")
    func upBody() {
        let digest = WeeklyDigest(totalDollars: 300, topCategoryName: "Rent", topCategoryDollars: 250, deltaDollars: 40)
        #expect(WeeklyDigest.body(for: digest).contains("up $40"))
    }

    @Test("flat week body")
    func flatBody() {
        let digest = WeeklyDigest(totalDollars: 100, topCategoryName: "Groceries", topCategoryDollars: 60, deltaDollars: 0)
        #expect(WeeklyDigest.body(for: digest).contains("same as last week"))
    }

    @Test("first week body omits comparison")
    func firstWeekBody() {
        let digest = WeeklyDigest(totalDollars: 50, topCategoryName: "Groceries", topCategoryDollars: 50, deltaDollars: nil)
        let body = WeeklyDigest.body(for: digest)
        #expect(body.contains("$50"))
        #expect(!body.contains("up $"))
        #expect(!body.contains("down $"))
        #expect(!body.contains("same as"))
    }

    // MARK: - nextFireDate

    @Test("midweek schedules coming Sunday 18:00")
    func midweek() {
        // Wednesday 2024-01-17 09:00 UTC.
        let now = Self.date("2024-01-17T09:00:00Z")
        #expect(WeeklyDigest.nextFireDate(after: now, calendar: Self.utc) == Self.fire)
    }

    @Test("Sunday before six schedules same day")
    func sundayBeforeSix() {
        let now = Self.date("2024-01-21T17:00:00Z")
        #expect(WeeklyDigest.nextFireDate(after: now, calendar: Self.utc) == Self.fire)
    }

    @Test("Sunday after six schedules following Sunday")
    func sundayAfterSix() {
        let now = Self.date("2024-01-21T19:00:00Z")
        #expect(WeeklyDigest.nextFireDate(after: now, calendar: Self.utc) == Self.date("2024-01-28T18:00:00Z"))
    }
}
