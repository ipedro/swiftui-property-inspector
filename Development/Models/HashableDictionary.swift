import Foundation

final class HashableDictionary<Key, Value>: Hashable where Key: Hashable, Value: Hashable {
    static func == (lhs: HashableDictionary<Key, Value>, rhs: HashableDictionary<Key, Value>) -> Bool {
        lhs.data == rhs.data
    }

    private var data = [Key: Value]()

    subscript(id: Key) -> Value? {
        get { data[id] }
        set { data[id] = newValue }
    }

    func hash(into hasher: inout Hasher) {
        data.hash(into: &hasher)
    }

    func removeAll() {
        data.removeAll(keepingCapacity: true)
    }
}
