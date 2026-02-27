import SwiftUI

/// 排便詳細記錄 Sheet - 含血便/黏液/急迫/疼痛等完整欄位
struct BowelDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let initialBristol: Int
    let onSave: (BowelMovement) -> Void
    
    @State private var bristolType: Int
    @State private var hasBlood: Bool = false
    @State private var hasMucus: Bool = false
    @State private var urgency: Int = 0
    @State private var completeness: Int = 2
    @State private var straining: Int = 0
    @State private var painLevel: Int = 0
    @State private var durationMinutes: Int = 0
    @State private var volume: Int = 2
    @State private var color: BowelColor = .brown
    @State private var notes: String = ""
    @State private var timestamp: Date = .now
    
    init(initialBristol: Int = 4, onSave: @escaping (BowelMovement) -> Void) {
        self.initialBristol = initialBristol
        self.onSave = onSave
        self._bristolType = State(initialValue: initialBristol)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // ── Bristol Type ──
                Section {
                    VStack(spacing: 12) {
                        BristolScalePicker(selectedType: $bristolType)
                        BristolDetailCard(info: BristolScale.info(for: bristolType))
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                } header: {
                    Text("Bristol 類型")
                }
                
                // ── 警示特徵 ──
                Section {
                    Toggle(isOn: $hasBlood) {
                        Label {
                            Text("血便")
                        } icon: {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .tint(.red)
                    
                    Toggle(isOn: $hasMucus) {
                        Label {
                            Text("黏液")
                        } icon: {
                            Image(systemName: "humidity.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .tint(.orange)
                } header: {
                    Text("特徵")
                }
                
                // ── 程度評估 ──
                Section {
                    severityPicker(title: "急迫感", value: $urgency,
                                   labels: [String(localized: "無"), String(localized: "輕微"), String(localized: "中等"), String(localized: "緊急")],
                                   icon: "bolt.fill", tint: .yellow)

                    severityPicker(title: "用力程度", value: $straining,
                                   labels: [String(localized: "無"), String(localized: "輕微"), String(localized: "中等"), String(localized: "嚴重")],
                                   icon: "arrow.down.circle.fill", tint: .purple)

                    severityPicker(title: "排空感", value: $completeness,
                                   labels: [String(localized: "不完全"), String(localized: "部分"), String(localized: "完全")],
                                   icon: "checkmark.circle.fill", tint: .green)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(.red)
                            Text("疼痛程度")
                            Spacer()
                            Text("\(painLevel)/10")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(painColor)
                        }
                        Slider(value: Binding(
                            get: { Double(painLevel) },
                            set: { painLevel = Int($0) }
                        ), in: 0...10, step: 1)
                        .tint(painColor)
                    }
                } header: {
                    Text("程度")
                }
                
                // ── 外觀 ──
                Section {
                    Picker("量", selection: $volume) {
                        Text("少").tag(1)
                        Text("正常").tag(2)
                        Text("多").tag(3)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("顏色", selection: $color) {
                        ForEach(BowelColor.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    
                    if color.warningLevel >= 2 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text("此顏色可能需要就醫，請諮詢醫生")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("外觀")
                }
                
                // ── 時間 & 備註 ──
                Section {
                    DatePicker("時間", selection: $timestamp)
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        Text("花費時間")
                        Spacer()
                        Stepper("\(durationMinutes) 分鐘", value: $durationMinutes, in: 0...60)
                            .font(.system(size: 14))
                    }
                } header: {
                    Text("時間")
                }
                
                Section {
                    TextField("備註...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("備註")
                }
            }
            .navigationTitle("詳細記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func severityPicker(title: String, value: Binding<Int>,
                                 labels: [String], icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
            }
            
            Picker(title, selection: value) {
                ForEach(0..<labels.count, id: \.self) { i in
                    Text(labels[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var painColor: Color {
        if painLevel <= 3 { return .green }
        if painLevel <= 6 { return .yellow }
        return .red
    }
    
    // MARK: - Save
    
    private func save() {
        let bm = BowelMovement(
            bristolType: bristolType,
            timestamp: timestamp,
            hasBlood: hasBlood,
            hasMucus: hasMucus,
            urgency: urgency,
            completeness: completeness,
            straining: straining,
            painLevel: painLevel,
            durationMinutes: durationMinutes,
            volume: volume,
            color: color,
            notes: notes
        )
        onSave(bm)
    }
}

#Preview {
    BowelDetailSheet(initialBristol: 4) { _ in }
}
