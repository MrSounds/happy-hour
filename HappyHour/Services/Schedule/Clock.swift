import Foundation

/// Supplies the current instant without coupling date calculations to `Date.now`.
protocol Clock: Sendable {
    var now: Date { get }
}

struct SystemClock: Clock {
    var now: Date { Date.now }
}

struct FixedClock: Clock {
    let now: Date
}
