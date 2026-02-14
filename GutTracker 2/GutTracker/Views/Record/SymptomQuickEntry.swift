import SwiftUI

/// 症狀快速輸入 - 點擊循環 severity 0→1→2→3→0
struct SymptomQuickEntry: View {
    @Binding var symptomEntry: SymptomEntry
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 8) {
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
            // Cycle: 0 → 1 → 2 → 3 → 0
            let next = (severity + 1) % 4
            setSeverity(for: type, value: next)
        } label: {
            VStack(spacing: 4) {
                Text(type.emoji)
                    .font(.system(size: 20))
                
                Text(type.displayName)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
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
            .frame(height: 68)
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
