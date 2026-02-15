import SwiftUI
import SwiftData
import WidgetKit
import HealthKit

struct RecordView: View {
    var body: some View {
        RecordViewContent(startOfToday: Calendar.current.startOfDay(for: .now))
    }
}

struct RecordViewContent: View {
    @Environment(\.modelContext) private var modelContext

    let startOfToday: Date

    @Query private var todayBowelMovements: [BowelMovement]
    @Query private var todayMedLogs: [MedicationLog]

    @Query(filter: #Predicate<Medication> { $0.isActive == true },
           sort: \Medication.sortOrder)
    private var activeMedications: [Medication]

    init(startOfToday: Date) {
        self.startOfToday = startOfToday
        _todayBowelMovements = Query(
            filter: #Predicate<BowelMovement> { $0.timestamp >= startOfToday },
            sort: \BowelMovement.timestamp,
            order: .reverse
        )
        _todayMedLogs = Query(
            filter: #Predicate<MedicationLog> { $0.timestamp >= startOfToday }
        )
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
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
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
            .background(Color(.systemGroupedBackground))
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
        .onDisappear {
            if let symptom = todaySymptom {
                syncSymptomToHealthKit(symptom)
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
                color: activeSymptomCount > 0 ? .orange : .green
            )
            Divider().frame(height: 28)
            statItem(
                value: "\(todayMedLogs.count)/\(activeMedications.count)",
                label: "用藥",
                color: todayMedLogs.count >= activeMedications.count ? .green : .yellow
            )
        }
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
    
    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Bowel Record Section
    
    private var bowelRecordSection: some View {
        SectionCard(title: "排便記錄", icon: "💩", accent: .brown) {
            VStack(spacing: 12) {
                Text("點擊 Bristol 類型即可記錄")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                
                BristolScalePicker(selectedType: $selectedBristol) { type in
                    quickRecordBowelMovement(bristolType: type)
                }
                
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
                            .fill(Color(.tertiarySystemGroupedBackground))
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
    
    // MARK: - Today's Records List
    
    private var todayRecordsList: some View {
        SectionCard(title: "今日記錄", icon: "📋", accent: .blue) {
            VStack(spacing: 6) {
                ForEach(todayBowelMovements) { record in
                    bowelRecordRow(record)
                }
            }
        }
    }
    
    private func bowelRecordRow(_ record: BowelMovement) -> some View {
        let info = record.bristolInfo
        return HStack(spacing: 10) {
            Text(info.emoji)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Type \(record.bristolType)")
                    .font(.system(size: 14, weight: .medium))
                
                HStack(spacing: 8) {
                    if record.hasBlood {
                        Label("血便", systemImage: "drop.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    if record.hasMucus {
                        Label("黏液", systemImage: "humidity.fill")
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
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }
    
    // MARK: - Symptom Section
    
    private var symptomSection: some View {
        SectionCard(title: "症狀追蹤", icon: "🤒", accent: .orange) {
            VStack(spacing: 8) {
                SymptomQuickEntry(symptomEntry: todaySymptomBinding)
                
                if let symptom = todaySymptom, symptom.hasActiveSymptoms {
                    Divider()
                    
                    FlowLayout(spacing: 6) {
                        ForEach(symptom.activeSymptomList, id: \.0) { (type, severity) in
                            HStack(spacing: 3) {
                                Text(type.emoji)
                                    .font(.system(size: 12))
                                Text("\(type.displayName)(\(severityLabels[severity]))")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                Capsule().fill(severityColor(severity).opacity(0.12))
                            }
                            .foregroundStyle(severityColor(severity))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Medication Section
    
    private var medicationSection: some View {
        SectionCard(
            title: "今日用藥",
            icon: "💊",
            accent: .cyan,
            trailing: {
                if todayMedLogs.count >= activeMedications.count && !activeMedications.isEmpty {
                    Text("✓ 完成")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }
        ) {
            if activeMedications.isEmpty {
                Button {
                    // Navigate to medication setup
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("新增藥物")
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
            } else {
                VStack(spacing: 6) {
                    ForEach(activeMedications) { med in
                        medicationRow(med)
                    }
                }
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
                        Capsule().fill(Color(.tertiarySystemGroupedBackground))
                    }
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isTaken ? Color.green.opacity(0.04) : Color(.tertiarySystemGroupedBackground))
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
    
    // MARK: - Overall Status Badge
    
    private var overallStatusBadge: some View {
        let score = NotificationService.shared.computeHealthScore(
            bowelMovements: todayBowelMovements,
            symptom: todaySymptom,
            medsTaken: todayMedLogs.count,
            medsTotal: activeMedications.count
        )
        return HStack(spacing: 4) {
            Text(score.level.emoji)
                .font(.system(size: 14))
            Text("\(score.score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule().fill(healthScoreColor(score.level).opacity(0.12))
        }
        .foregroundStyle(healthScoreColor(score.level))
        .animation(.easeInOut(duration: 0.3), value: score.score)
    }
    
    // MARK: - Confirmation Overlay
    
    private var confirmationOverlay: some View {
        let info = BristolScale.info(for: confirmedBristol)
        return VStack(spacing: 10) {
            Text(info.emoji)
                .font(.system(size: 52))
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
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 0: return .secondary
        case 1: return .green
        case 2: return .yellow
        case 3: return .red
        default: return .secondary
        }
    }
    
    private func statusColor(_ status: OverallStatus) -> Color {
        switch status {
        case .good: return .green
        case .mild: return .green
        case .moderate: return .yellow
        case .severe: return .red
        }
    }

    private func healthScoreColor(_ level: HealthScoreLevel) -> Color {
        switch level {
        case .excellent, .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

// MARK: - Section Card

struct SectionCard<Content: View, Trailing: View>: View {
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
                .fill(Color(.secondarySystemGroupedBackground))
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

