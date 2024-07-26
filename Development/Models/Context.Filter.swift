import SwiftUI

extension Context {
    final class Filter<F> {
        var wrappedValue: F
        var isOn: Bool

        init(_ wrappedValue: F, isOn: Bool) {
            self.wrappedValue = wrappedValue
            self.isOn = isOn
        }
    }
}

extension Context.Filter: Hashable where F: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension Context.Filter: Equatable where F: Equatable {
    static func == (lhs: Context.Filter<F>, rhs: Context.Filter<F>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Context.Filter: Comparable where F: Comparable {
    static func < (rhs: Context.Filter<F>, lhs: Context.Filter<F>) -> Bool {
        if rhs.isOn == lhs.isOn {
            rhs.wrappedValue < lhs.wrappedValue
        } else {
            rhs.isOn && !lhs.isOn
        }
    }
}
