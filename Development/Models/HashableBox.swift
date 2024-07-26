import Foundation

struct HashableBox<Value>: Hashable {
    let id = UUID()
    let value: Value

    init(_ value: Value) {
        self.value = value
    }

    static func == (lhs: HashableBox<Value>, rhs: HashableBox<Value>) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
