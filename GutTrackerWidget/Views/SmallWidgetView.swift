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
                Text("💩")
                    .font(.system(size: 14))
                Text("\(entry.bowelCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("次")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Bristol types
            if !entry.bristolTypes.isEmpty {
                HStack(spacing: 2) {
                    Text("Bristol")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    ForEach(entry.bristolTypes.suffix(5), id: \.self) { type in
                        Text(BristolScale.info(for: type).emoji)
                            .font(.system(size: 12))
                    }
                }
            }

            Spacer()

            // 底部：用藥進度
            HStack {
                if entry.hasBlood {
                    Text("🩸")
                        .font(.system(size: 10))
                }
                Spacer()
                if entry.medsTotal > 0 {
                    Text("💊 \(entry.medsTaken)/\(entry.medsTotal)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(entry.medsTaken == entry.medsTotal ? .green : .orange)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
