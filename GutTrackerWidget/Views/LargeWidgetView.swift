import AppIntents
import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: GutTrackerEntry

    @AppStorage("appTheme", store: UserDefaults(suiteName: Constants.appGroupIdentifier))
    private var themeRaw: String = AppTheme.cream.rawValue

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .cream }

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

            // Bristol 互動按鈕（全 7 種，顏色對比改善）
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { type in
                    Button(intent: RecordBowelMovementIntent(bristolType: type)) {
                        VStack(spacing: 2) {
                            BristolShapeView(
                                type: type,
                                color: bristolIconColor(type),
                                size: 20
                            )
                            Text("\(type)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(bristolIconColor(type))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(bristolBackground(type))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(bristolStroke(type), lineWidth: 1.5)
                                }
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

            // 症狀快速 toggle
            HStack(spacing: 4) {
                ForEach(widgetSymptoms, id: \.rawValue) { type in
                    let isActive = entry.activeSymptomTypes.contains(type.rawValue)
                    Button(intent: ToggleSymptomIntent(symptomType: type)) {
                        HStack(spacing: 2) {
                            Text(widgetSymptomIcon(type))
                                .font(.system(size: 11))
                                .foregroundStyle(isActive ? ZenColors.amber : Color(red: 0.2, green: 0.18, blue: 0.15))
                            Text(type.displayName)
                                .font(.system(size: 11, weight: isActive ? .semibold : .medium))
                                .foregroundStyle(isActive ? ZenColors.amber : Color(red: 0.2, green: 0.18, blue: 0.15))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isActive ? ZenColors.amber.opacity(0.18) : Color.white.opacity(0.82))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(
                                            isActive ? ZenColors.amber : Color(red: 0.2, green: 0.18, blue: 0.15).opacity(0.25),
                                            lineWidth: 1
                                        )
                                }
                        }
                    }
                    .buttonStyle(.plain)
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
        .containerBackground(theme.elevated, for: .widget)
    }

    private var widgetSymptoms: [SymptomType] {
        entry.widgetSymptomTypes.compactMap { SymptomType(rawValue: $0) }
    }

    private func widgetSymptomIcon(_ type: SymptomType) -> String {
        switch type {
        case .abdominalPain: return "◎"
        case .bloating: return "○"
        case .nausea: return "〜"
        case .fatigue: return "⌒"
        default: return ""
        }
    }

    private func bristolBackground(_ type: Int) -> Color {
        entry.bristolTypes.contains(type)
            ? ZenColors.bristolZone(for: type).opacity(0.18)
            : Color.white.opacity(0.82)
    }

    private func bristolStroke(_ type: Int) -> Color {
        entry.bristolTypes.contains(type)
            ? ZenColors.bristolZone(for: type)
            : ZenColors.bristolZone(for: type).opacity(0.60)
    }

    private func bristolIconColor(_ type: Int) -> Color {
        entry.bristolTypes.contains(type)
            ? ZenColors.bristolZone(for: type)
            : ZenColors.bristolZone(for: type).opacity(0.80)
    }

    private func riskColor(_ risk: BristolRisk) -> Color {
        switch risk {
        case .normal: return .green
        case .constipation: return .orange
        case .diarrhea: return .red
        }
    }
}

#Preview("Large — 有記錄", as: .systemLarge) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.placeholder
}

#Preview("Large — 空白", as: .systemLarge) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.empty
}
