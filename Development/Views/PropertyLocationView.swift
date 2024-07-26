import SwiftUI

struct PropertyLocationView: View {
    var data: PropertyLocation

    var body: some View {
        text
            .lineLimit(1)
            .truncationMode(.head)
            .foregroundStyle(.secondary)
    }

    var text: some View {
        Text(verbatim: data.function) +
            Text(verbatim: " — ").bold().ios17_quinaryForegroundStyle() +
            Text(verbatim: data.description)
    }
}

private extension Text {
    func ios17_quinaryForegroundStyle() -> Text {
        if #available(iOS 17.0, *) {
            self.foregroundStyle(.quinary)
        } else {
            // Fallback on earlier versions
            self
        }
    }
}
