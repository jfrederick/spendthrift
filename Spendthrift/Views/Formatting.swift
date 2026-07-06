import Foundation

// Int.wholeDollars moved to SpendthriftCore (DollarFormatting.swift) so the
// digest notification copy shares the exact formatter the views use.

/// Shared "Today"/"Yesterday"/date day label used by the totals list and the
/// drill-in expense list.
func dayLabel(for date: Date, calendar: Calendar = .current) -> String {
    if calendar.isDateInToday(date) {
        return "Today"
    }
    if calendar.isDateInYesterday(date) {
        return "Yesterday"
    }
    return date.formatted(.dateTime.month(.abbreviated).day().year())
}
