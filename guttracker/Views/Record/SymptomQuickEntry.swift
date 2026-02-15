import SwiftUI

/// 症狀快速輸入 - 點擊循環 severity 0→1→2→3→0
/// 常見症狀（3 欄大按鈕）+ 次要症狀（4 欄可收合）
struct SymptomQuickEntry: View {
    @Binding var symptomEntry: SymptomEntry
    @State private var showSecondary = false

    private let commonColumns = Array(repeating: GridItem(.flexible()), count: 3)
    private let secondaryColumns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        VStack(spacing: 10) {
            // 常見症狀 — 3 欄，大按鈕
            LazyVGrid(columns: commonColumns, spacing: 8) {
                ForEach(SymptomType.commonSymptoms) { type in
                    symptomButton(type, height: 76)
                }
            }

            // 更多症狀 toggle
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showSecondary.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showSecondary ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                    Text("更多症狀")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
            }

            // 次要症狀 — 4 欄，小按鈕
            if showSecondary {
                LazyVGrid(columns: secondaryColumns, spacing: 8) {
                    ForEach(SymptomType.secondarySymptoms) { type in
                        symptomButton(type, height: 68)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func symptomButton(_ type: SymptomType, height: CGFloat) -> some View {
        let severity = getSeverity(for: type)
        let isActive = severity > 0

        Button {
            let next = (severity + 1) % 4
            setSeverity(for: type, value: next)
        } label: {
            VStack(spacing: 4) {
                Text(type.emoji)
                    .font(.system(size: height > 70 ? 22 : 18))

                Text(type.displayName)
                    .font(.system(size: height > 70 ? 11 : 10, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? severityColor(severity) : .secondary)

                // Severity dots
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { level in
                        Circle()
                            .fill(severity >= level ? severityColor(level) : Color(.systemGray5))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? severityColor(severity).opacity(0.08) : Color(.tertiarySystemGroupedBackground))
                    .overlay {
                        if isActive {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(severityColor(severity).opacity(0.25), lineWidth: 1)
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

    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 1: return .green
        case 2: return .yellow
        case 3: return .red
        default: return .secondary
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
