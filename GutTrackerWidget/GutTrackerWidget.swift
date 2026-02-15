import WidgetKit
import SwiftUI

struct GutTrackerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GutTrackerEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct GutTrackerWidget: Widget {
    let kind = Constants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GutTrackerTimelineProvider()) { entry in
            GutTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GutTracker")
        .description("追蹤今日排便、症狀與用藥狀態")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.placeholder
}

#Preview(as: .systemMedium) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.placeholder
}

#Preview(as: .systemLarge) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.placeholder
}
