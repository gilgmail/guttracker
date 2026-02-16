import AppIntents
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: GutTrackerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: 排便次數 + avg Bristol + 症狀狀態
            HStack {
                Text("\(entry.bowelCount)次")
                    .font(.system(size: 15, weight: .light, design: .rounded))
                if entry.avgBristol > 0 {
                    Text("avg")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    BristolShapeView(
                        type: Int(entry.avgBristol.rounded()),
                        color: ZenColors.bristolZone(for: Int(entry.avgBristol.rounded())),
                        size: 14
                    )
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

            // 底部：活躍症狀 + 血便/黏液標記
            HStack(spacing: 6) {
                if !entry.activeSymptomNames.isEmpty {
                    Text(entry.activeSymptomNames.prefix(3).joined(separator: " "))
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
                Spacer()
                if entry.hasBlood {
                    Text("血便")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.red)
                }
                if entry.hasMucus {
                    Text("黏液")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func bristolBackground(_ type: Int) -> Color {
        let isCurrent = entry.bristolTypes.last == type
        if isCurrent {
            return ZenColors.bristolZone(for: type).opacity(0.2)
        }
        return Color(.systemGray5)
    }

    private func bristolIconColor(_ type: Int) -> Color {
        let isCurrent = entry.bristolTypes.last == type
        return isCurrent ? ZenColors.bristolZone(for: type) : .secondary
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
