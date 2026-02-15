import AppIntents
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: GutTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: 排便次數 + avg Bristol + 症狀狀態
            HStack {
                Text("💩")
                    .font(.system(size: 13))
                Text("\(entry.bowelCount)次")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                if entry.avgBristol > 0 {
                    Text("avg")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(BristolScale.info(for: Int(entry.avgBristol.rounded())).emoji)
                        .font(.system(size: 13))
                }
                Spacer()
                Text(entry.symptomStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(severityColor)
            }

            // 全寬 Bristol 互動按鈕
            HStack(spacing: 3) {
                ForEach(1...7, id: \.self) { type in
                    Button(intent: RecordBowelMovementIntent(bristolType: type)) {
                        VStack(spacing: 2) {
                            Text(BristolScale.info(for: type).emoji)
                                .font(.system(size: 18))
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

            // 底部：活躍症狀 + 血便/黏液標記
            HStack(spacing: 6) {
                if !entry.activeSymptomNames.isEmpty {
                    Text(entry.activeSymptomNames.prefix(3).joined(separator: " "))
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                Spacer()
                if entry.hasBlood {
                    HStack(spacing: 2) {
                        Text("🩸")
                            .font(.system(size: 11))
                        Text("血便")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
                if entry.hasMucus {
                    HStack(spacing: 2) {
                        Text("💧")
                            .font(.system(size: 11))
                        Text("黏液")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
            }
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
