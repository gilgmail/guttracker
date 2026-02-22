import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Query(sort: \BowelMovement.timestamp) private var allBowelMovements: [BowelMovement]
    @Query(sort: \SymptomEntry.timestamp) private var allSymptoms: [SymptomEntry]
    @Query(sort: \MedicationLog.timestamp) private var allMedLogs: [MedicationLog]
    @Query(filter: #Predicate<Medication> { $0.isActive == true })
    private var activeMeds: [Medication]

    @State private var displayedMonth: Date = .now
    @State private var selectedDate: Date? = nil
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @State private var healthSleep: Double?
    @State private var healthSteps: Int?
    @State private var healthHR: Int?
    
    private let calendar = Calendar.current
    private let weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeaderRow
                    calendarGrid
                    legendRow
                    
                    if let selected = selectedDate {
                        dayDetailCard(for: selected)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(theme.background)
            .navigationTitle("日曆")
            .animation(.easeInOut(duration: 0.25), value: selectedDate)
        }
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(monthYearString)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var monthYearString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: displayedMonth)
    }
    
    private func shiftMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
            selectedDate = nil
        }
    }
    
    // MARK: - Weekday Headers
    
    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day = day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }
    
    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let dayBMs = bowelMovements(for: date)
        let daySym = symptomEntry(for: date)
        let dayNum = calendar.component(.day, from: date)
        let isFuture = date > Date.now
        let hasBlood = dayBMs.contains { $0.hasBlood }
        let severity = daySym?.overallSeverity ?? 0
        
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = isSelected ? nil : date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(dayNum)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(isFuture ? AnyShapeStyle(.quaternary) : isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
                
                if !dayBMs.isEmpty {
                    HStack(spacing: 1) {
                        Circle()
                            .fill(hasBlood ? .red : severityColor(severity))
                            .frame(width: 5, height: 5)
                        if hasBlood {
                            Circle().fill(.red).frame(width: 5, height: 5)
                        }
                    }
                } else {
                    Color.clear.frame(height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? .green : dayBMs.isEmpty ? theme.elevated :
                            hasBlood ? .red.opacity(0.08) : severityColor(severity).opacity(0.06))
            }
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.green.opacity(0.5), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }
    
    // MARK: - Legend
    
    private var legendRow: some View {
        HStack(spacing: 16) {
            ForEach([(Color.green, "良好"), (.yellow, "輕微"), (.orange, "中等"), (.red, "嚴重")], id: \.1) { c in
                HStack(spacing: 3) {
                    Circle().fill(c.0).frame(width: 6, height: 6)
                    Text(c.1).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Day Detail Card
    
    @ViewBuilder
    private func dayDetailCard(for date: Date) -> some View {
        let dayBMs = bowelMovements(for: date)
        let daySym = symptomEntry(for: date)
        let dayMeds = medicationLogs(for: date)
        let severity = daySym?.overallSeverity ?? 0
        let status = daySym?.overallStatus ?? .good
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date.dateWithWeekday)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(status.emoji) \(status.displayName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(severityColor(severity == 0 ? 0 : severity))
            }
            
            Divider()
            
            // Bowel movements
            detailRow(icon: "drop.fill", iconColor: .brown, title: dayBMs.isEmpty ? "無排便記錄" : "\(dayBMs.count) 次排便") {
                ForEach(dayBMs) { bm in
                    HStack(spacing: 6) {
                        Text(bm.bristolInfo.emoji).font(.system(size: 14))
                        Text("Type \(bm.bristolType)").font(.system(size: 12))
                        if bm.hasBlood { Text("🩸").font(.system(size: 10)) }
                        if bm.painLevel > 0 {
                            Text("痛:\(bm.painLevel)").font(.system(size: 10)).foregroundStyle(.orange)
                        }
                        Spacer()
                        Text(bm.timestamp.timeString)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            // Symptoms
            if let sym = daySym, sym.hasActiveSymptoms {
                detailRow(icon: "waveform.path.ecg", iconColor: .orange, title: "症狀") {
                    FlowLayout(spacing: 4) {
                        ForEach(sym.activeSymptomList, id: \.0) { (type, sev) in
                            Text("\(type.emoji) \(type.displayName)(\(severityLabels[sev]))")
                                .font(.system(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background { Capsule().fill(severityColor(sev).opacity(0.1)) }
                                .foregroundStyle(severityColor(sev))
                        }
                    }
                }
            }
            
            // Meds
            if !activeMeds.isEmpty {
                detailRow(icon: "pills.fill", iconColor: .cyan,
                          title: "用藥 \(dayMeds.filter { $0.taken }.count)/\(activeMeds.count)") {
                    HStack(spacing: 8) {
                        ForEach(activeMeds) { med in
                            let taken = dayMeds.contains { $0.medicationName == med.name }
                            HStack(spacing: 3) {
                                Image(systemName: taken ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(taken ? .green : .secondary)
                                Text(med.name).font(.system(size: 11))
                            }
                        }
                    }
                }
            }

            // Health data
            if healthKitEnabled, healthSleep != nil || healthSteps != nil || healthHR != nil {
                Divider()
                detailRow(icon: "heart.fill", iconColor: .red, title: "Apple Health") {
                    HStack(spacing: 16) {
                        if let sleep = healthSleep {
                            HStack(spacing: 3) {
                                Text("😴").font(.system(size: 12))
                                Text(String(format: "%.1fh", sleep))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                        }
                        if let steps = healthSteps {
                            HStack(spacing: 3) {
                                Text("🚶").font(.system(size: 12))
                                Text("\(steps.formatted())")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                        }
                        if let hr = healthHR {
                            HStack(spacing: 3) {
                                Text("❤️").font(.system(size: 12))
                                Text("\(hr) bpm")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.card)
        }
        .task(id: date) {
            guard healthKitEnabled else { return }
            await fetchHealthData(for: date)
        }
    }
    
    @ViewBuilder
    private func detailRow<Content: View>(icon: String, iconColor: Color, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .medium))
                content()
            }
        }
    }
    
    // MARK: - Health Data

    private func fetchHealthData(for date: Date) async {
        healthSleep = nil
        healthSteps = nil
        healthHR = nil

        let service = HealthKitService.shared
        healthSleep = try? await service.fetchSleepHours(for: date)
        healthSteps = try? await service.fetchSteps(for: date)
        healthHR = try? await service.fetchRestingHeartRate(for: date)
    }

    // MARK: - Data Helpers

    private func daysInMonth() -> [Date?] {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday + 5) % 7  // Monday-based
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            days.append(calendar.date(bySetting: .day, value: day, of: firstOfMonth))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
    
    private func bowelMovements(for date: Date) -> [BowelMovement] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return allBowelMovements.filter { $0.timestamp >= start && $0.timestamp < end }
    }
    
    private func symptomEntry(for date: Date) -> SymptomEntry? {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return allSymptoms.first { $0.timestamp >= start && $0.timestamp < end }
    }
    
    private func medicationLogs(for date: Date) -> [MedicationLog] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return allMedLogs.filter { $0.timestamp >= start && $0.timestamp < end }
    }
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        default: return .red
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [BowelMovement.self, SymptomEntry.self, MedicationLog.self, Medication.self], inMemory: true)
}
