import AppIntents
import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: GutTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("GutTracker")
                    .font(.system(size: 13, weight: .semibold))
                Text(Date.now.shortDateString)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.symptomStatus)
                    .font(.system(size: 12, weight: .medium))
            }

            Divider()

            // 排便區
            HStack {
                Text("排便 \(entry.bowelCount)次")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if entry.avgBristol > 0 {
                    Text("Bristol avg: \(String(format: "%.1f", entry.avgBristol))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // Bristol 互動按鈕
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { type in
                    Button(intent: RecordBowelMovementIntent(bristolType: type)) {
                        VStack(spacing: 1) {
                            BristolShapeView(
                                type: type,
                                color: bristolIconColor(type),
                                size: 18
                            )
                            Text("\(type)")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(bristolBackground(type))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // 最近記錄
            if !entry.recentRecords.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(entry.recentRecords.enumerated()), id: \.offset) { _, record in
                        HStack(spacing: 8) {
                            Text(record.time)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text("Type \(record.bristolType)")
                                .font(.system(size: 11, weight: .medium))
                            BristolShapeView(
                                type: record.bristolType,
                                color: ZenColors.bristolZone(for: record.bristolType),
                                size: 12
                            )
                            Text(record.risk.displayName)
                                .font(.system(size: 10))
                                .foregroundStyle(riskColor(record.risk))
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Divider()

            // 症狀摘要
            if !entry.activeSymptomNames.isEmpty {
                HStack(spacing: 4) {
                    Text("症狀:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.activeSymptomNames.prefix(4).joined(separator: "  "))
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
            }

            // 警示標記
            HStack(spacing: 12) {
                if entry.hasBlood {
                    Text("今日有血便記錄")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                }
                if entry.hasMucus {
                    Text("今日有黏液記錄")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func bristolBackground(_ type: Int) -> Color {
        if entry.bristolTypes.contains(type) {
            return ZenColors.bristolZone(for: type).opacity(0.2)
        }
        return Color(.systemGray5)
    }

    private func bristolIconColor(_ type: Int) -> Color {
        entry.bristolTypes.contains(type) ? ZenColors.bristolZone(for: type) : .secondary
    }

    private func riskColor(_ risk: BristolRisk) -> Color {
        switch risk {
        case .normal: return .green
        case .constipation: return .orange
        case .diarrhea: return .red
        }
    }
}
