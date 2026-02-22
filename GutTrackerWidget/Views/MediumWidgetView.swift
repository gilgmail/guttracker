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

            // 症狀快速 toggle
            HStack(spacing: 4) {
                ForEach(widgetSymptoms, id: \.rawValue) { type in
                    let isActive = entry.activeSymptomTypes.contains(type.rawValue)
                    Button(intent: ToggleSymptomIntent(symptomType: type)) {
                        HStack(spacing: 2) {
                            Text(widgetSymptomIcon(type))
                                .font(.system(size: 10))
                            Text(type.displayName)
                                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isActive ? ZenColors.amber.opacity(0.2) : theme.inactive)
                        }
                        .foregroundStyle(isActive ? ZenColors.amber : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .containerBackground(theme.elevated, for: .widget)
    }

    private var widgetSymptoms: [SymptomType] {
        [.abdominalPain, .bloating, .nausea, .fatigue]
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
        let isCurrent = entry.bristolTypes.last == type
        if isCurrent {
            return ZenColors.bristolZone(for: type).opacity(0.2)
        }
        return theme.inactive
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
