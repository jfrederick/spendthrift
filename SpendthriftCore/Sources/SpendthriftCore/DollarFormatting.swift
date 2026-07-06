import Foundation

/// Shared display formatting (design D3: whole-dollar currency, zero
/// fraction digits, everywhere — views and notification copy alike).
public extension Int {
    var wholeDollars: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
