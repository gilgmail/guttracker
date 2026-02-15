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
                Text("💩 排便 \(entry.bowelCount)次")
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
                            Text(BristolScale.info(for: type).emoji)
                                .font(.system(size: 16))
                            Text("\(type)")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
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
                            Text("Type\(record.bristolType)")
                                .font(.system(size: 11, weight: .medium))
                            Text(BristolScale.info(for: record.bristolType).emoji)
                                .font(.system(size: 11))
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

            // 用藥區
            HStack(spacing: 6) {
                Text("💊")
                    .font(.system(size: 12))
                ForEach(Array(entry.medications.prefix(4).enumerated()), id: \.offset) { _, med in
                    HStack(spacing: 2) {
                        Text(med.name)
                            .font(.system(size: 10))
                            .lineLimit(1)
                        Image(systemName: med.taken ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(med.taken ? .green : .secondary)
                    }
                }
                Spacer()
            }

            if entry.hasBlood {
                HStack(spacing: 4) {
                    Text("🩸")
                        .font(.system(size: 11))
                    Text("今日有血便記錄")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func bristolBackground(_ type: Int) -> Color {
        if entry.bristolTypes.contains(type) {
            return BristolScale.info(for: type).color.opacity(0.25)
        }
        return Color(.systemGray5)
    }

    private func riskColor(_ risk: BristolRisk) -> Color {
        switch risk {
        case .normal: return .green
        case .constipation: return .orange
        case .diarrhea: return .red
        }
    }
}
