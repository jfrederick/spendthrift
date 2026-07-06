import Foundation
import SwiftData
import Testing
import SpendthriftCore
@testable import Spendthrift

/// Store-level coverage of the digest content pipeline (`upcomingDigest` is
/// exactly what `refresh` schedules) and the preference default. The
/// UNUserNotificationCenter calls themselves are framework glue left to
/// manual/UI verification.
@MainActor
struct DigestSchedulerTests {
    /// Wednesday 2024-01-17 09:00 UTC — fire date is Sunday 2024-01-21 18:00 UTC.
    static let wednesday = Date(timeIntervalSince1970: 1_705_482_000)

    static var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test func upcomingDigestSummarizesTrailingWeek() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let food = try #require(try store.category(named: "Food & Drink"))
        let transport = try #require(try store.category(named: "Transport"))
        // In the trailing window (Sun 14th 18:00 -> Sun 21st 18:00): 120 + 94.
        try store.saveExpense(amountDollars: 120, label: "groceries run", category: food, timestamp: Self.wednesday)
        try store.saveExpense(amountDollars: 94, label: "gas", category: transport, timestamp: Self.wednesday.addingTimeInterval(-86_400))
        // Prior window: 246.
        try store.saveExpense(amountDollars: 246, label: "flight", category: transport, timestamp: Self.wednesday.addingTimeInterval(-8 * 86_400))

        let upcoming = try #require(DigestScheduler.upcomingDigest(store: store, now: Self.wednesday, calendar: Self.utc))

        #expect(upcoming.digest.totalDollars == 214)
        #expect(upcoming.digest.topCategoryName == "Food & Drink")
        #expect(upcoming.digest.deltaDollars == -32)
        #expect(upcoming.fireDate == Date(timeIntervalSince1970: 1_705_860_000)) // Sun 21st 18:00 UTC
    }

    @Test func upcomingDigestIncludesJustSavedExpense() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()
        let food = try #require(try store.category(named: "Food & Drink"))
        try store.saveExpense(amountDollars: 10, label: "cafe", category: food, timestamp: Self.wednesday)
        let before = DigestScheduler.upcomingDigest(store: store, now: Self.wednesday, calendar: Self.utc)

        try store.saveExpense(amountDollars: 5, label: "snack", category: food, timestamp: Self.wednesday)
        let after = DigestScheduler.upcomingDigest(store: store, now: Self.wednesday, calendar: Self.utc)

        #expect(before?.digest.totalDollars == 10)
        #expect(after?.digest.totalDollars == 15)
    }

    @Test func upcomingDigestNilForEmptyWeek() throws {
        let (_, store) = try TestSupport.makeStore()
        try store.seedIfNeeded()

        #expect(DigestScheduler.upcomingDigest(store: store, now: Self.wednesday, calendar: Self.utc) == nil)
    }

    @Test func preferenceDefaultsToOff() throws {
        let suite = "digest-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = DigestPreferences.userDefaults
        DigestPreferences.userDefaults = defaults
        defer { DigestPreferences.userDefaults = original }

        #expect(DigestPreferences.isEnabled == false)
        DigestPreferences.isEnabled = true
        #expect(DigestPreferences.isEnabled == true)
    }
}
