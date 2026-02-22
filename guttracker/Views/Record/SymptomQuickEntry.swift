import SwiftUI

/// 症狀快速輸入 — 統一 4 欄 flat grid + 抽象圖標
/// 點擊循環 severity 0→1→2→3→0
struct SymptomQuickEntry: View {
    @Environment(\.appTheme) private var theme
    @Binding var symptomEntry: SymptomEntry

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(SymptomType.allCases) { type in
                symptomButton(type)
            }
        }
    }

    @ViewBuilder
    private func symptomButton(_ type: SymptomType) -> some View {
        let severity = getSeverity(for: type)
        let isActive = severity > 0

        Button {
            let next = (severity + 1) % 4
            setSeverity(for: type, value: next)
        } label: {
            VStack(spacing: 5) {
                SymptomIconView(
                    type: type,
                    color: isActive ? ZenColors.amber : .secondary,
                    size: 20
                )

                Text(type.displayName)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? ZenColors.amber : .secondary)

                // Severity dots — only when active
                if isActive {
                    HStack(spacing: 2) {
                        ForEach(1...3, id: \.self) { level in
                            Circle()
                                .fill(severity >= level ? ZenColors.amber : theme.inactive)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 68)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
                    .overlay {
                        if isActive {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(ZenColors.amber.opacity(0.3), lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: severity)
    }

    // MARK: - Severity Access

    private func getSeverity(for type: SymptomType) -> Int {
        switch type {
        case .abdominalPain: return symptomEntry.abdominalPain
        case .bloating: return symptomEntry.bloating
        case .gas: return symptomEntry.gas
        case .nausea: return symptomEntry.nausea
        case .cramping: return symptomEntry.cramping
        case .bowelSounds: return symptomEntry.bowelSounds
        case .fatigue: return symptomEntry.fatigue
        case .fever: return symptomEntry.fever ? 2 : 0
        case .jointPain: return symptomEntry.jointPain
        }
    }

    private func setSeverity(for type: SymptomType, value: Int) {
        symptomEntry.updatedAt = .now
        switch type {
        case .abdominalPain: symptomEntry.abdominalPain = value
        case .bloating: symptomEntry.bloating = value
        case .gas: symptomEntry.gas = value
        case .nausea: symptomEntry.nausea = value
        case .cramping: symptomEntry.cramping = value
        case .bowelSounds: symptomEntry.bowelSounds = value
        case .fatigue: symptomEntry.fatigue = value
        case .fever: symptomEntry.fever = value > 0
        case .jointPain: symptomEntry.jointPain = value
        }
    }
}

#Preview {
    struct Wrapper: View {
        @State var entry = SymptomEntry()
        var body: some View {
            SymptomQuickEntry(symptomEntry: $entry)
                .padding()
        }
    }
    return Wrapper()
}
