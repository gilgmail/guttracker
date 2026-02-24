import AppIntents
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: GutTrackerEntry

    @AppStorage("appTheme", store: UserDefaults(suiteName: Constants.appGroupIdentifier))
    private var themeRaw: String = AppTheme.cream.rawValue

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .cream }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: 排便次數 + avg Bristol shape + 症狀狀態
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

            // 智慧 Bristol 互動按鈕（只顯示近 30 天最常用的類型）
            HStack(spacing: 5) {
                ForEach(entry.smartBristolTypes, id: \.self) { type in
                    Button(intent: RecordBowelMovementIntent(bristolType: type)) {
                        VStack(spacing: 3) {
                            BristolShapeView(
                                type: type,
                                color: bristolIconColor(type),
                                size: 22
                            )
                            Text("\(type)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(bristolIconColor(type))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(bristolBackground(type))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(bristolStroke(type), lineWidth: 1.5)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

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

    // MARK: - Button Appearance

    /// 已記錄今日：zone 色 tint；未記錄：白色卡片（與米色背景明確分隔）
    private func bristolBackground(_ type: Int) -> Color {
        entry.bristolTypes.contains(type)
            ? ZenColors.bristolZone(for: type).opacity(0.18)
            : Color.white.opacity(0.82)
    }

    /// 已記錄：zone 顏色實線；未記錄：zone 顏色 60% 邊框
    private func bristolStroke(_ type: Int) -> Color {
        entry.bristolTypes.contains(type)
            ? ZenColors.bristolZone(for: type)
            : ZenColors.bristolZone(for: type).opacity(0.60)
    }

    /// 已記錄：zone 顏色；未記錄：zone 顏色 80%
    private func bristolIconColor(_ type: Int) -> Color {
        entry.bristolTypes.contains(type)
            ? ZenColors.bristolZone(for: type)
            : ZenColors.bristolZone(for: type).opacity(0.80)
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

#Preview("Medium — 有記錄", as: .systemMedium) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.placeholder
}

#Preview("Medium — 空白", as: .systemMedium) {
    GutTrackerWidget()
} timeline: {
    GutTrackerEntry.empty
}
