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
                    .foregroundStyle(widgetPrimaryText)
                Text(Date.now.shortDateString)
                    .font(.system(size: 12))
                    .foregroundStyle(widgetSecondaryText)
                Spacer()
                Text(entry.symptomStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(widgetPrimaryText)
            }

            Divider()

            // 排便區
            HStack {
                Text("排便 \(entry.bowelCount)次")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(widgetPrimaryText)
                Spacer()
                if entry.avgBristol > 0 {
                    Text("Bristol avg: \(String(format: "%.1f", entry.avgBristol))")
                        .font(.system(size: 11))
                        .foregroundStyle(widgetSecondaryText)
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
                                .foregroundStyle(widgetSecondaryText)
                            Text("Type \(record.bristolType)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(widgetPrimaryText)
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
                                .foregroundStyle(isActive ? ZenColors.amber : widgetPrimaryText)
                            Text(type.displayName)
                                .font(.system(size: 11, weight: isActive ? .semibold : .medium))
                                .foregroundStyle(isActive ? ZenColors.amber : widgetPrimaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isActive ? ZenColors.amber.opacity(0.18) : symptomInactiveBg)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(
                                            isActive ? ZenColors.amber : widgetPrimaryText.opacity(0.25),
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
        case .bloating:      return "○"
        case .gas:           return "≋"
        case .nausea:        return "〜"
        case .cramping:      return "⚡"
        case .bowelSounds:   return "♪"
        case .fatigue:       return "⌒"
        case .fever:         return "△"
        case .jointPain:     return "⊕"
        }
    }

    // MARK: - Theme-Aware Colors

    private var widgetPrimaryText: Color {
        theme == .cream
            ? Color(red: 0.114, green: 0.227, blue: 0.165)  // #1C3A2A 深森林綠
            : Color.white.opacity(0.90)
    }

    private var widgetSecondaryText: Color {
        theme == .cream
            ? Color(red: 0.114, green: 0.227, blue: 0.165).opacity(0.55)
            : Color.white.opacity(0.55)
    }

    private var symptomInactiveBg: Color {
        theme == .cream
            ? Color.white.opacity(0.82)
            : Color(white: 0.28).opacity(0.80)
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
