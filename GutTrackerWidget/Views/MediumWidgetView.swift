import AppIntents
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: GutTrackerEntry

    var body: some View {
        HStack(spacing: 12) {
            // 左側：排便
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Text("💩")
                        .font(.system(size: 12))
                    Text("\(entry.bowelCount)次")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    if entry.avgBristol > 0 {
                        Text("avg")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(BristolScale.info(for: Int(entry.avgBristol.rounded())).emoji)
                            .font(.system(size: 12))
                    }
                }

                // Bristol 按鈕列
                HStack(spacing: 3) {
                    ForEach(1...7, id: \.self) { type in
                        Button(intent: RecordBowelMovementIntent(bristolType: type)) {
                            Text(BristolScale.info(for: type).emoji)
                                .font(.system(size: 14))
                                .frame(width: 26, height: 26)
                                .background {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(bristolBackground(type))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 症狀
                Text(entry.symptomStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(severityColor)
            }

            Divider()

            // 右側：用藥
            VStack(alignment: .leading, spacing: 4) {
                Text("💊 用藥")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)

                if entry.medications.isEmpty {
                    Text("尚無藥物")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(Array(entry.medications.prefix(3).enumerated()), id: \.offset) { _, med in
                        HStack(spacing: 4) {
                            Image(systemName: med.taken ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 11))
                                .foregroundStyle(med.taken ? .green : .secondary)
                            Text(med.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func bristolBackground(_ type: Int) -> Color {
        let isCurrent = entry.bristolTypes.last == type
        if isCurrent {
            return BristolScale.info(for: type).color.opacity(0.3)
        }
        return Color(.systemGray5)
    }

    private var severityColor: Color {
        switch entry.symptomSeverity {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        default: return .red
        }
    }
}
