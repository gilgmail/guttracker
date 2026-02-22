import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme

    @Query(sort: \Medication.sortOrder)
    private var medications: [Medication]

    @State private var showAddMed: Bool = false
    @State private var showDefaultMeds: Bool = false
    @AppStorage("appTheme", store: UserDefaults(suiteName: Constants.appGroupIdentifier))
    private var selectedTheme: String = AppTheme.cream.rawValue
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("dailyScoreEnabled") private var dailyScoreEnabled = false
    @AppStorage("dailyScoreHour") private var dailyScoreHour = 9
    @AppStorage("dailyScoreMinute") private var dailyScoreMinute = 0
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
                                        Capsule().fill(theme.elevated)
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
                    Toggle(isOn: Binding(
                        get: { notificationsEnabled },
                        set: { newValue in
                            notificationsEnabled = newValue
                            rescheduleNotifications()
                        }
                    )) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("用藥提醒")
                                Text("依照各藥物設定的時間提醒服藥")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.fill")
                        }
                    }
                    .tint(.blue)

                    Toggle(isOn: Binding(
                        get: { dailyScoreEnabled },
                        set: { newValue in
                            dailyScoreEnabled = newValue
                            if newValue { notificationsEnabled = true }
                            rescheduleNotifications()
                        }
                    )) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("每日健康評分")
                                Text("每天早上推送昨日健康評分與摘要")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                    .tint(.green)

                    if dailyScoreEnabled {
                        DatePicker(
                            "推送時間",
                            selection: dailyScoreTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: dailyScoreHour) { rescheduleNotifications() }
                        .onChange(of: dailyScoreMinute) { rescheduleNotifications() }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    if notificationsEnabled {
                        Text("用藥提醒時間可在各藥物的編輯頁面設定。健康評分會根據排便、症狀、用藥計算 0-100 分。")
                    }
                }
                
                // ── 外觀 ──
                Section {
                    Picker("主題", selection: Binding(
                        get: { AppTheme(rawValue: selectedTheme) ?? .cream },
                        set: { selectedTheme = $0.rawValue }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                } header: {
                    Text("外觀")
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
                        Text("1.0.0")
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
    
    private var dailyScoreTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = dailyScoreHour
                components.minute = dailyScoreMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                dailyScoreHour = components.hour ?? 9
                dailyScoreMinute = components.minute ?? 0
            }
        )
    }

    private func rescheduleNotifications() {
        NotificationService.shared.rescheduleAll(
            container: modelContext.container
        )
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
    @Environment(\.appTheme) private var theme
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
                                .background { Capsule().fill(theme.elevated) }
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
    @Bindable var medication: Medication
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    var body: some View {
        Form {
            Section("基本資訊") {
                HStack {
                    Text("名稱")
                    Spacer()
                    Text(medication.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("分類")
                    Spacer()
                    Text(medication.category.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("劑量")
                    Spacer()
                    Text(medication.defaultDosage)
                        .foregroundStyle(.secondary)
                }
                Picker("頻率", selection: $medication.frequency) {
                    ForEach(MedFrequency.allCases, id: \.self) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                Toggle("啟用", isOn: $medication.isActive)
            }

            Section {
                Toggle("用藥提醒", isOn: $medication.reminderEnabled)
                    .tint(.blue)

                if medication.reminderEnabled {
                    DatePicker(
                        "提醒時間",
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("提醒")
            } footer: {
                if !notificationsEnabled && medication.reminderEnabled {
                    Text("請先在設定頁開啟「用藥提醒」通知")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(medication.name)
        .onChange(of: medication.reminderEnabled) { reschedule() }
        .onChange(of: medication.reminderHour) { reschedule() }
        .onChange(of: medication.reminderMinute) { reschedule() }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = medication.reminderHour
                components.minute = medication.reminderMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                medication.reminderHour = components.hour ?? 8
                medication.reminderMinute = components.minute ?? 0
            }
        )
    }

    private func reschedule() {
        NotificationService.shared.rescheduleAll(
            container: medication.modelContext?.container ?? SharedContainer.modelContainer
        )
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
