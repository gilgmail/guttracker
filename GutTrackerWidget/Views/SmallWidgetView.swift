import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: GutTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("GutTracker")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.symptomStatus)
                    .font(.system(size: 10))
            }

            Spacer()

            // 排便次數
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.bowelCount)")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                Text("次排便")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // 最近 Bristol type
            if let lastType = entry.bristolTypes.last {
                let info = BristolScale.info(for: lastType)
                HStack(spacing: 4) {
                    Text("最近:")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    BristolShapeView(type: lastType, color: info.color, size: 14)
                    Text("Type \(lastType)")
                        .font(.system(size: 10, weight: .medium))
                }
            }

            Spacer()

            // 底部：症狀 + 警示
            HStack(spacing: 4) {
                if !entry.activeSymptomNames.isEmpty {
                    Text(entry.activeSymptomNames.prefix(2).joined(separator: " "))
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
                Spacer()
                if entry.hasBlood {
                    Text("血")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.red)
                }
                if entry.hasMucus {
                    Text("液")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
