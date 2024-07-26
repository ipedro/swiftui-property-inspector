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
    static func == (a: Context.Filter<F>, b: Context.Filter<F>) -> Bool {
        a.wrappedValue == b.wrappedValue
    }
}

extension Context.Filter: Comparable where F: Comparable {
    static func < (a: Context.Filter<F>, b: Context.Filter<F>) -> Bool {
        if a.isOn == b.isOn {
            a.wrappedValue < b.wrappedValue
        } else {
            a.isOn && !b.isOn
        }
    }
}
