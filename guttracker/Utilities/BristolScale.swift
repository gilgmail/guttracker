import SwiftUI

/// Bristol Stool Scale - 7 種排便分類
enum BristolScale {
    
    struct Info {
        let type: Int
        let emoji: String
        let name: String
        let description: String
        let risk: BristolRisk
        let color: Color
        let sfSymbol: String
    }
    
    static func info(for type: Int) -> Info {
        let clamped = max(1, min(7, type))
        return allTypes[clamped - 1]
    }
    
    static let allTypes: [Info] = [
        Info(type: 1, emoji: "🪨", name: "硬塊",
             description: "分離的硬塊，如堅果狀",
             risk: .constipation,
             color: Color(red: 0.55, green: 0.27, blue: 0.07),
             sfSymbol: "circle.grid.3x3.fill"),
        
        Info(type: 2, emoji: "🥜", name: "塊狀",
             description: "表面凹凸的條狀",
             risk: .constipation,
             color: Color(red: 0.63, green: 0.32, blue: 0.18),
             sfSymbol: "oval.fill"),
        
        Info(type: 3, emoji: "🌰", name: "裂紋",
             description: "表面有裂紋的條狀",
             risk: .normal,
             color: Color(red: 0.42, green: 0.56, blue: 0.14),
             sfSymbol: "rectangle.roundedtop.fill"),
        
        Info(type: 4, emoji: "🍌", name: "正常",
             description: "光滑柔軟的條狀",
             risk: .normal,
             color: Color(red: 0.18, green: 0.55, blue: 0.34),
             sfSymbol: "rectangle.fill"),
        
        Info(type: 5, emoji: "☁️", name: "軟塊",
             description: "邊緣清楚的軟塊",
             risk: .normal,
             color: Color(red: 0.27, green: 0.51, blue: 0.71),
             sfSymbol: "cloud.fill"),
        
        Info(type: 6, emoji: "🫧", name: "糊狀",
             description: "邊緣不規則的糊狀",
             risk: .diarrhea,
             color: Color(red: 0.82, green: 0.41, blue: 0.12),
             sfSymbol: "drop.halffull"),
        
        Info(type: 7, emoji: "💧", name: "水狀",
             description: "完全液體狀，無固體",
             risk: .diarrhea,
             color: Color(red: 0.80, green: 0.36, blue: 0.36),
             sfSymbol: "drop.fill"),
    ]
}

// MARK: - Bristol Scale Picker View

struct BristolScalePicker: View {
    @Binding var selectedType: Int
    var onSelect: ((Int) -> Void)?

    @State private var animatingType: Int? = nil

    private let spectrumColors: [Color] = [
        Color(red: 0.55, green: 0.27, blue: 0.07),
        Color(red: 0.63, green: 0.32, blue: 0.18),
        Color(red: 0.42, green: 0.56, blue: 0.14),
        Color(red: 0.18, green: 0.55, blue: 0.34),
        Color(red: 0.27, green: 0.51, blue: 0.71),
        Color(red: 0.82, green: 0.41, blue: 0.12),
        Color(red: 0.80, green: 0.36, blue: 0.36),
    ]

    var body: some View {
        VStack(spacing: 6) {
            // 硬 ← → 軟 labels
            HStack {
                Text("硬")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("軟")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // 7 buttons in one row
            HStack(spacing: 4) {
                ForEach(BristolScale.allTypes, id: \.type) { info in
                    bristolButton(info)
                }
            }

            // Gradient spectrum bar
            LinearGradient(
                colors: spectrumColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .clipShape(Capsule())
            .opacity(0.6)

            // Selected risk label
            let selectedInfo = BristolScale.info(for: selectedType)
            Text(selectedInfo.risk.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedInfo.color)
                .animation(.easeInOut(duration: 0.2), value: selectedType)
        }
    }

    @ViewBuilder
    private func bristolButton(_ info: BristolScale.Info) -> some View {
        let isSelected = selectedType == info.type
        let isAnimating = animatingType == info.type

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedType = info.type
                animatingType = info.type
            }
            onSelect?(info.type)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { animatingType = nil }
            }
        } label: {
            VStack(spacing: 3) {
                Text(info.emoji)
                    .font(.system(size: 24))

                Text("\(info.type)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? info.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? info.color.opacity(0.15) : Color(.systemGray6))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(info.color.opacity(0.4), lineWidth: 1.5)
                        }
                    }
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .shadow(color: isSelected ? info.color.opacity(0.2) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
    }
}

// MARK: - Bristol Detail Card

struct BristolDetailCard: View {
    let info: BristolScale.Info
    
    var body: some View {
        HStack(spacing: 12) {
            Text(info.emoji)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Type \(info.type)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    
                    Text(info.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Text(info.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Risk badge
            Text(info.risk.displayName)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(riskColor(info.risk).opacity(0.12))
                }
                .foregroundStyle(riskColor(info.risk))
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }
    
    private func riskColor(_ risk: BristolRisk) -> Color {
        switch risk {
        case .constipation: return .orange
        case .normal: return .green
        case .diarrhea: return .red
        }
    }
}

#Preview("Bristol Picker") {
    struct PreviewWrapper: View {
        @State var selected = 4
        var body: some View {
            VStack(spacing: 20) {
                BristolScalePicker(selectedType: $selected)
                BristolDetailCard(info: BristolScale.info(for: selected))
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
