import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Medication.sortOrder)
    private var medications: [Medication]

    @State private var showAddMed: Bool = false
    @State private var showDefaultMeds: Bool = false
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var healthKitAuthError: String?
    
    var body: some View {
        NavigationStack {
            Form {
                // ── 藥物管理 ──
                Section {
                    ForEach(medications) { med in
                        NavigationLink {
                            MedicationEditView(medication: med)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.name)
                                        .font(.system(size: 15, weight: .medium))
                                    Text("\(med.defaultDosage) · \(med.frequency.displayName)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(med.category.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background {
                                        Capsule().fill(Color(.tertiarySystemGroupedBackground))
                                    }
                                    .foregroundStyle(.secondary)
                                
                                if !med.isActive {
                                    Text("停用")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteMedication)
                    
                    Button {
                        showAddMed = true
                    } label: {
                        Label("新增藥物", systemImage: "plus.circle")
                    }
                    
                    if medications.isEmpty {
                        Button {
                            showDefaultMeds = true
                        } label: {
                            Label("從常見 IBD 藥物中選擇", systemImage: "list.bullet")
                        }
                    }
                } header: {
                    Text("藥物管理")
                } footer: {
                    Text("設定目前使用的藥物，每日用藥清單會顯示在記錄頁")
                }
                
                // ── HealthKit ──
                Section {
                    if HKHealthStore.isHealthDataAvailable() {
                        Toggle(isOn: Binding(
                            get: { healthKitEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        do {
                                            try await HealthKitService.shared.requestAuthorization()
                                            healthKitEnabled = true
                                            healthKitAuthError = nil
                                        } catch {
                                            healthKitEnabled = false
                                            healthKitAuthError = error.localizedDescription
                                        }
                                    }
                                } else {
                                    healthKitEnabled = false
                                }
                            }
                        )) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Apple Health 同步")
                                    Text("排便/症狀資料同步到健康 App")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .tint(.green)

                        if healthKitEnabled {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 14))
                                Text("已連接 Apple Health")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "heart.slash.fill")
                                .foregroundStyle(.secondary)
                            Text("此裝置不支援 HealthKit")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("健康整合")
                } footer: {
                    if let error = healthKitAuthError {
                        Text("授權失敗：\(error)")
                            .foregroundStyle(.red)
                    } else {
                        Text("開啟後，排便和症狀記錄會自動同步到 Apple Health，也會讀取睡眠和步數資料。")
                    }
                }
                
                // ── 通知 ──
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("用藥提醒", systemImage: "bell.fill")
                    }
                    .tint(.blue)
                } header: {
                    Text("通知")
                }
                
                // ── 資料 ──
                Section {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("資料管理", systemImage: "externaldrive.fill")
                    }
                } header: {
                    Text("資料")
                }
                
                // ── 關於 ──
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0 (Phase 1)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("關於")
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showAddMed) {
                MedicationAddSheet { med in
                    modelContext.insert(med)
                }
            }
            .sheet(isPresented: $showDefaultMeds) {
                DefaultMedicationPicker { selectedMeds in
                    for med in selectedMeds {
                        modelContext.insert(med)
                    }
                }
            }
        }
    }
    
    private func deleteMedication(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(medications[index])
        }
    }
}

// MARK: - Medication Add Sheet

struct MedicationAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Medication) -> Void
    
    @State private var name: String = ""
    @State private var nameEN: String = ""
    @State private var category: MedCategory = .other
    @State private var dosage: String = ""
    @State private var frequency: MedFrequency = .daily
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("藥物名稱", text: $name)
                    TextField("英文名稱（選填）", text: $nameEN)
                }
                
                Section {
                    Picker("分類", selection: $category) {
                        ForEach(MedCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    
                    TextField("劑量", text: $dosage)
                        .keyboardType(.default)
                    
                    Picker("頻率", selection: $frequency) {
                        ForEach(MedFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }
            }
            .navigationTitle("新增藥物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("新增") {
                        let med = Medication(
                            name: name,
                            nameEN: nameEN,
                            category: category,
                            defaultDosage: dosage,
                            frequency: frequency
                        )
                        onSave(med)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Default Medication Picker

struct DefaultMedicationPicker: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: ([Medication]) -> Void
    
    @State private var selected: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<DefaultMedications.all.count, id: \.self) { index in
                    let data = DefaultMedications.all[index]
                    let isSelected = selected.contains(index)
                    
                    Button {
                        if isSelected { selected.remove(index) }
                        else { selected.insert(index) }
                    } label: {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? .green : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(data.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text("\(data.nameEN) · \(data.dosage) · \(data.frequency.displayName)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(data.category.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background { Capsule().fill(Color(.tertiarySystemGroupedBackground)) }
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("常見 IBD 藥物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("新增 (\(selected.count))") {
                        let meds = selected.map { DefaultMedications.createMedication(at: $0) }
                        onSelect(meds)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selected.isEmpty)
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct MedicationEditView: View {
    let medication: Medication
    var body: some View {
        Text("編輯 \(medication.name) — Phase 1 後續完善")
            .navigationTitle(medication.name)
    }
}

struct DataManagementView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("資料匯出 / 清除")
                .font(.headline)
            Text("Phase 2 實作")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("資料管理")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Medication.self, MedicationLog.self], inMemory: true)
}
