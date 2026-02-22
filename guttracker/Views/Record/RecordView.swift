import SwiftUI
import SwiftData
import WidgetKit
import HealthKit

struct RecordView: View {
    var body: some View {
        RecordViewContent()
    }
}

struct RecordViewContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTheme) private var theme

    @Query(sort: \BowelMovement.timestamp, order: .reverse)
    private var allBowelMovements: [BowelMovement]

    @Query(sort: \MedicationLog.timestamp, order: .reverse)
    private var allMedLogs: [MedicationLog]

    @Query(filter: #Predicate<Medication> { $0.isActive == true },
           sort: \Medication.sortOrder)
    private var activeMedications: [Medication]

    // Computed: always-fresh today filter
    private var todayBowelMovements: [BowelMovement] {
        let today = Calendar.current.startOfDay(for: .now)
        return allBowelMovements.filter { $0.timestamp >= today }
    }

    private var todayMedLogs: [MedicationLog] {
        let today = Calendar.current.startOfDay(for: .now)
        return allMedLogs.filter { $0.timestamp >= today }
    }

    @State private var selectedBristol: Int = 4
    @State private var showBowelDetail: Bool = false
    @State private var showSymptomSheet: Bool = false
    @State private var todaySymptom: SymptomEntry?

    // Confirmation animation
    @State private var showConfirmation: Bool = false
    @State private var confirmedBristol: Int = 0

    // HealthKit
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false

    // Navigation
    @State private var showMedicationSetup = false

    // Problem indicators
    @State private var showNoBowelAlert = false

    // Medication collapse
    @State private var showMedsExpanded = false

    // Delete record
    @State private var recordToDelete: BowelMovement?

    // Records collapse
    @State private var showRecordsExpanded = false

    // Refresh trigger for date change
    @State private var refreshID = UUID()

    // Entrance animation
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── 今日統計條 ──
                    todayStatsBar
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    // ── 排便快速記錄 ──
                    bowelRecordSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    // ── 今日排便記錄列表 ──
                    if !todayBowelMovements.isEmpty {
                        todayRecordsList
                    }

                    // ── 症狀快速記錄 ──
                    symptomSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // ── 用藥 Checklist ──
                    medicationSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 24)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .animation(.easeOut(duration: 0.5), value: todayBowelMovements.count)
            }
            .background(theme.background)
            .navigationTitle("GutTracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    overallStatusBadge
                }
            }
        }
        .overlay {
            if showConfirmation {
                confirmationOverlay
            }
        }
        .onAppear {
            loadTodaySymptom()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshID = UUID()
                loadTodaySymptom()
            }
        }
        .id(refreshID)
        .onDisappear {
            if let symptom = todaySymptom {
                syncSymptomToHealthKit(symptom)
            }
        }
        .alert("尚無排便記錄", isPresented: $showNoBowelAlert) {
            Button("好") {}
        } message: {
            Text("請先記錄排便，再標記血便/黏液")
        }
        .alert("刪除記錄？", isPresented: .init(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        )) {
            Button("取消", role: .cancel) { recordToDelete = nil }
            Button("刪除", role: .destructive) { deleteRecord() }
        } message: {
            if let record = recordToDelete {
                Text("確定刪除 Type \(record.bristolType) (\(record.timestamp.formatted(.dateTime.hour().minute()))) 的記錄？")
            }
        }
    }

    // MARK: - Today Stats Bar

    private var todayStatsBar: some View {
        HStack(spacing: 0) {
            statItem(value: "\(todayBowelMovements.count)", label: "排便次數", color: .primary)
            Divider().frame(height: 28)
            statItem(value: avgBristolString, label: "Bristol 均值", color: .primary)
            Divider().frame(height: 28)
            statItem(
                value: "\(activeSymptomCount)",
                label: "活躍症狀",
                color: activeSymptomCount > 0 ? ZenColors.amber : ZenColors.bristolNormal
            )
        }
        .padding(.vertical, 12)
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .light, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bowel Record Section

    private var bowelRecordSection: some View {
        ZenSection(title: "排便記錄") {
            VStack(spacing: 12) {
                Text("點擊 Bristol 類型即可記錄")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)

                BristolScalePicker(selectedType: $selectedBristol) { type in
                    quickRecordBowelMovement(bristolType: type)
                }

                // 問題標記（血便 / 黏液）
                problemIndicatorsRow

                // 詳細記錄按鈕
                Button {
                    showBowelDetail = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("詳細記錄")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.elevated)
                    }
                }
            }
        }
        .sheet(isPresented: $showBowelDetail) {
            BowelDetailSheet(initialBristol: selectedBristol) { bm in
                modelContext.insert(bm)
                WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)
                syncBowelMovementToHealthKit(bm)
            }
        }
    }

    // MARK: - Problem Indicators

    private var problemIndicatorsRow: some View {
        HStack(spacing: 8) {
            problemToggle(
                label: "血便",
                isActive: todayBowelMovements.first?.hasBlood ?? false,
                activeColor: .red
            ) {
                guard let latest = todayBowelMovements.first else {
                    showNoBowelAlert = true
                    return
                }
                latest.hasBlood.toggle()
            }

            problemToggle(
                label: "黏液",
                isActive: todayBowelMovements.first?.hasMucus ?? false,
                activeColor: .orange
            ) {
                guard let latest = todayBowelMovements.first else {
                    showNoBowelAlert = true
                    return
                }
                latest.hasMucus.toggle()
            }
        }
    }

    private func problemToggle(label: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isActive ? activeColor.opacity(0.12) : theme.elevated)
                        .overlay {
                            if isActive {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(activeColor.opacity(0.4), lineWidth: 1.5)
                            }
                        }
                }
                .foregroundStyle(isActive ? activeColor : .secondary)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isActive)
    }

    // MARK: - Today's Records List

    private var todayRecordsList: some View {
        VStack(spacing: 0) {
            // Collapsed header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRecordsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("今日記錄")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(todayBowelMovements.count) 筆")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Image(systemName: showRecordsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded records
            if showRecordsExpanded {
                VStack(spacing: 6) {
                    ForEach(todayBowelMovements) { record in
                        bowelRecordRow(record)
                    }
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func bowelRecordRow(_ record: BowelMovement) -> some View {
        let info = record.bristolInfo
        return HStack(spacing: 10) {
            BristolShapeView(type: record.bristolType, color: info.color, size: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text("Type \(record.bristolType)")
                    .font(.system(size: 14, weight: .medium))

                HStack(spacing: 8) {
                    if record.hasBlood {
                        Text("血便")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    if record.hasMucus {
                        Text("黏液")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Risk badge
            Text(info.risk.displayName)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule().fill(info.color.opacity(0.12))
                }
                .foregroundStyle(info.color)

            Text(record.timestamp.formatted(.dateTime.hour().minute()))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.elevated)
        }
        .contextMenu {
            Button(role: .destructive) {
                recordToDelete = record
            } label: {
                Label("刪除記錄", systemImage: "trash")
            }
        }
    }

    // MARK: - Symptom Section

    private var symptomSection: some View {
        ZenSection(title: "症狀追蹤") {
            VStack(spacing: 8) {
                SymptomQuickEntry(symptomEntry: todaySymptomBinding)

                if let symptom = todaySymptom, symptom.hasActiveSymptoms {
                    Divider()

                    FlowLayout(spacing: 6) {
                        ForEach(symptom.activeSymptomList, id: \.0) { (type, severity) in
                            HStack(spacing: 3) {
                                SymptomIconView(type: type, color: ZenColors.amber, size: 12)
                                Text("\(type.displayName)(\(severityLabels[severity]))")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                Capsule().fill(ZenColors.amber.opacity(0.12))
                            }
                            .foregroundStyle(ZenColors.amber)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Medication Section

    private var medicationSection: some View {
        VStack(spacing: 0) {
            // Collapsed header — always visible
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showMedsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("今日用藥")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !activeMedications.isEmpty {
                        let done = todayMedLogs.count >= activeMedications.count
                        Text("\(todayMedLogs.count)/\(activeMedications.count) \(done ? "✓" : "")")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(done ? ZenColors.bristolNormal : .secondary)
                    }
                    Image(systemName: showMedsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if showMedsExpanded {
                VStack(spacing: 6) {
                    if activeMedications.isEmpty {
                        Button {
                            showMedicationSetup = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("新增藥物（前往設定）")
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(.quaternary)
                            }
                        }
                        .sheet(isPresented: $showMedicationSetup) {
                            NavigationStack {
                                SettingsView()
                            }
                        }
                    } else {
                        ForEach(activeMedications) { med in
                            medicationRow(med)
                        }
                    }
                }
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func medicationRow(_ med: Medication) -> some View {
        let isTaken = todayMedLogs.contains { $0.medicationName == med.name }

        return Button {
            toggleMedication(med)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isTaken ? .green : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(med.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isTaken ? .secondary : .primary)
                        .strikethrough(isTaken)

                    Text(med.defaultDosage)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(med.category.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule().fill(theme.elevated)
                    }
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isTaken ? Color.green.opacity(0.04) : theme.elevated)
                    .overlay {
                        if isTaken {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.green.opacity(0.15), lineWidth: 1)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isTaken)
    }

    // MARK: - Overall Status Badge (WellnessRing)

    private var overallStatusBadge: some View {
        let score = NotificationService.shared.computeHealthScore(
            bowelMovements: todayBowelMovements,
            symptom: todaySymptom,
            medsTaken: todayMedLogs.count,
            medsTotal: activeMedications.count
        )
        return WellnessRing(score: score.score, level: score.level, diameter: 32)
            .animation(.easeInOut(duration: 0.3), value: score.score)
    }

    // MARK: - Confirmation Overlay

    private var confirmationOverlay: some View {
        let info = BristolScale.info(for: confirmedBristol)
        return VStack(spacing: 10) {
            BristolShapeView(type: confirmedBristol, color: info.color, size: 52)
                .scaleEffect(showConfirmation ? 1.0 : 0.3)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showConfirmation)

            Text("已記錄 Type \(confirmedBristol)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)
                .scaleEffect(showConfirmation ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15), value: showConfirmation)
        }
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    // MARK: - Actions

    private func quickRecordBowelMovement(bristolType: Int) {
        let bm = BowelMovement(bristolType: bristolType)
        modelContext.insert(bm)
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)
        syncBowelMovementToHealthKit(bm)

        confirmedBristol = bristolType
        withAnimation(.spring(response: 0.3)) {
            showConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showConfirmation = false }
        }
    }

    private func deleteRecord() {
        guard let record = recordToDelete else { return }
        withAnimation {
            modelContext.delete(record)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)
        recordToDelete = nil
    }

    private func toggleMedication(_ med: Medication) {
        if let existing = todayMedLogs.first(where: { $0.medicationName == med.name }) {
            modelContext.delete(existing)
        } else {
            let log = MedicationLog(
                medicationName: med.name,
                category: med.category,
                dosage: med.defaultDosage
            )
            log.medicationId = med.id
            modelContext.insert(log)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)
    }

    private func loadTodaySymptom() {
        // Find or create today's symptom entry
        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= today },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            todaySymptom = existing
        } else {
            let entry = SymptomEntry()
            modelContext.insert(entry)
            todaySymptom = entry
        }
    }

    private var todaySymptomBinding: Binding<SymptomEntry> {
        Binding(
            get: { todaySymptom ?? SymptomEntry() },
            set: { todaySymptom = $0 }
        )
    }

    // MARK: - HealthKit Sync

    private func syncBowelMovementToHealthKit(_ bm: BowelMovement) {
        guard healthKitEnabled else { return }
        Task {
            do {
                let uuid = try await HealthKitService.shared.syncBowelMovement(bm)
                bm.healthKitSynced = true
                bm.healthKitUUID = uuid
            } catch {
                // Silently fail — user can see sync status in settings
            }
        }
    }

    private func syncSymptomToHealthKit(_ entry: SymptomEntry) {
        guard healthKitEnabled, !entry.healthKitSynced, entry.hasActiveSymptoms else { return }
        Task {
            do {
                try await HealthKitService.shared.syncSymptomEntry(entry)
                entry.healthKitSynced = true
            } catch {
                // Silently fail
            }
        }
    }

    // MARK: - Helpers

    private var avgBristolString: String {
        guard !todayBowelMovements.isEmpty else { return "-" }
        let avg = Double(todayBowelMovements.reduce(0) { $0 + $1.bristolType }) / Double(todayBowelMovements.count)
        return String(format: "%.1f", avg)
    }

    private var activeSymptomCount: Int {
        todaySymptom?.activeSymptomList.count ?? 0
    }

    private func healthScoreColor(_ level: HealthScoreLevel) -> Color {
        switch level {
        case .excellent, .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

// MARK: - Zen Section (minimal header + divider)

struct ZenSection<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .tracking(1)
                .foregroundStyle(.secondary)

            content()
        }
    }
}

// MARK: - Section Card (retained for BowelDetailSheet)

struct SectionCard<Content: View, Trailing: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let icon: String
    let accent: Color
    let trailing: () -> Trailing
    let content: () -> Content

    init(
        title: String,
        icon: String,
        accent: Color,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accent = accent
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(icon)
                    .font(.system(size: 15))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                Spacer()
                trailing()
            }

            content()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.card)
        }
    }
}

// MARK: - Flow Layout (for symptom tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    RecordView()
        .modelContainer(for: [
            BowelMovement.self,
            SymptomEntry.self,
            MedicationLog.self,
            Medication.self,
        ], inMemory: true)
}
