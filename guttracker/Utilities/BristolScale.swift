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
             color: ZenColors.bristolHard,
             sfSymbol: "circle.grid.3x3.fill"),

        Info(type: 2, emoji: "🥜", name: "塊狀",
             description: "表面凹凸的條狀",
             risk: .constipation,
             color: ZenColors.bristolHard,
             sfSymbol: "oval.fill"),

        Info(type: 3, emoji: "🌰", name: "裂紋",
             description: "表面有裂紋的條狀",
             risk: .normal,
             color: ZenColors.bristolNormal,
             sfSymbol: "rectangle.roundedtop.fill"),

        Info(type: 4, emoji: "🍌", name: "正常",
             description: "光滑柔軟的條狀",
             risk: .normal,
             color: ZenColors.bristolNormal,
             sfSymbol: "rectangle.fill"),

        Info(type: 5, emoji: "☁️", name: "軟塊",
             description: "邊緣清楚的軟塊",
             risk: .normal,
             color: ZenColors.bristolNormal,
             sfSymbol: "cloud.fill"),

        Info(type: 6, emoji: "🫧", name: "糊狀",
             description: "邊緣不規則的糊狀",
             risk: .diarrhea,
             color: ZenColors.bristolSoft,
             sfSymbol: "drop.halffull"),

        Info(type: 7, emoji: "💧", name: "水狀",
             description: "完全液體狀，無固體",
             risk: .diarrhea,
             color: ZenColors.bristolSoft,
             sfSymbol: "drop.fill"),
    ]
}

// MARK: - Bristol Scale Picker View

struct BristolScalePicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var selectedType: Int
    var onSelect: ((Int) -> Void)?

    @State private var animatingType: Int? = nil

    private let zoneColors: [Color] = [
        ZenColors.bristolHard,
        ZenColors.bristolHard,
        ZenColors.bristolNormal,
        ZenColors.bristolNormal,
        ZenColors.bristolNormal,
        ZenColors.bristolSoft,
        ZenColors.bristolSoft,
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

            // 3-zone gradient bar
            LinearGradient(
                colors: zoneColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)
            .clipShape(Capsule())
            .opacity(0.5)

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
        let zoneColor = ZenColors.bristolZone(for: info.type)

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
                BristolShapeView(
                    type: info.type,
                    color: isSelected ? zoneColor : .secondary,
                    size: 22
                )

                Text("\(info.type)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? zoneColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? zoneColor.opacity(0.12) : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected ? zoneColor.opacity(0.4) : theme.inactive,
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    }
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
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
            BristolShapeView(type: info.type, color: info.color, size: 32)

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
