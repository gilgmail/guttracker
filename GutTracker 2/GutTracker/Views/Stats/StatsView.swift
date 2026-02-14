import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \BowelMovement.timestamp) private var allBMs: [BowelMovement]
    @Query(sort: \SymptomEntry.timestamp) private var allSymptoms: [SymptomEntry]
    @Query(sort: \MedicationLog.timestamp) private var allMedLogs: [MedicationLog]
    @Query(filter: #Predicate<Medication> { $0.isActive == true })
    private var activeMeds: [Medication]
    
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var showExport: Bool = false
    
    enum StatsPeriod: String, CaseIterable {
        case week = "7天"
        case month = "30天"
        case quarter = "90天"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    private var summaries: [AnalyticsEngine.DailySummary] {
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: end)!
        return AnalyticsEngine.dailySummaries(
            bowelMovements: allBMs,
            symptoms: allSymptoms,
            medLogs: allMedLogs,
            totalMeds: activeMeds.count,
            from: start, to: end
        )
    }
    
    private var stats: AnalyticsEngine.PeriodStats {
        AnalyticsEngine.periodStats(from: summaries)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Period selector
                    periodPicker
                    
                    // Summary cards
                    summaryCards
                    
                    // Bowel frequency chart
                    if stats.totalBowelMovements > 0 {
                        bowelFrequencyChart
                        bristolDistributionChart
                        symptomTrendChart
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("統計")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ExportSheet(stats: stats, summaries: summaries, period: selectedPeriod)
            }
        }
    }
    
    // MARK: - Period Picker
    
    private var periodPicker: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            summaryCard(
                title: "平均排便",
                value: String(format: "%.1f", stats.avgBowelPerDay),
                unit: "次/天",
                icon: "💩",
                trend: stats.bowelTrend
            )
            summaryCard(
                title: "Bristol 均值",
                value: String(format: "%.1f", stats.avgBristol),
                unit: "",
                icon: BristolScale.info(for: Int(stats.avgBristol.rounded())).emoji,
                trend: nil
            )
            summaryCard(
                title: "血便天數",
                value: "\(stats.bloodDays)",
                unit: "天",
                icon: "🩸",
                trend: nil,
                isWarning: stats.bloodDays > 0
            )
            summaryCard(
                title: "平均疼痛",
                value: String(format: "%.1f", stats.avgPain),
                unit: "/10",
                icon: "😣",
                trend: stats.symptomTrend
            )
        }
    }
    
    private func summaryCard(title: String, value: String, unit: String, icon: String,
                              trend: AnalyticsEngine.Trend?, isWarning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(icon).font(.system(size: 14))
                Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                Spacer()
                if let trend = trend {
                    Text(trend.emoji)
                        .font(.system(size: 11))
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(isWarning ? .red : .primary)
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            if let trend = trend {
                Text(trend.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(trendColor(trend))
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: - Bowel Frequency Chart
    
    private var bowelFrequencyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("排便頻率趨勢")
                .font(.system(size: 15, weight: .semibold))
            
            Chart(summaries) { day in
                BarMark(
                    x: .value("日期", day.date, unit: .day),
                    y: .value("次數", day.bowelCount)
                )
                .foregroundStyle(
                    day.hasBlood ? .red :
                    day.bowelCount > 5 ? .orange :
                    .green
                )
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)").font(.system(size: 10))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                        .font(.system(size: 9))
                    AxisGridLine()
                }
            }
            .frame(height: 160)
            
            // Average line description
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("正常").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(.orange).frame(width: 6, height: 6)
                    Text("偏多(>5)").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 6, height: 6)
                    Text("含血便").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: - Bristol Distribution Chart
    
    private var bristolDistributionChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bristol 分布")
                .font(.system(size: 15, weight: .semibold))
            
            Chart {
                ForEach(BristolScale.allTypes, id: \.type) { info in
                    let count = stats.bristolDistribution[info.type] ?? 0
                    BarMark(
                        x: .value("次數", count),
                        y: .value("類型", "Type \(info.type) \(info.emoji)")
                    )
                    .foregroundStyle(info.color)
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 200)
            
            // Risk summary
            HStack(spacing: 16) {
                riskBadge(label: "便秘", count: stats.constipationDays, color: .orange, icon: "🪨")
                riskBadge(label: "正常", count: stats.normalDays, color: .green, icon: "🍌")
                riskBadge(label: "腹瀉", count: stats.diarrheaDays, color: .red, icon: "💧")
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
    
    private func riskBadge(label: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 16))
            Text("\(count)天")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.06))
        }
    }
    
    // MARK: - Symptom Trend Chart
    
    private var symptomTrendChart: some View {
        let symDays = summaries.filter { $0.symptomSeverity > 0 || $0.bowelCount > 0 }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("症狀趨勢")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(stats.symptomTrend.emoji) \(stats.symptomTrend.displayName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(trendColor(stats.symptomTrend))
            }
            
            Chart(summaries) { day in
                LineMark(
                    x: .value("日期", day.date, unit: .day),
                    y: .value("嚴重度", day.symptomSeverity)
                )
                .foregroundStyle(.orange.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("日期", day.date, unit: .day),
                    y: .value("嚴重度", day.symptomSeverity)
                )
                .foregroundStyle(.orange.opacity(0.08).gradient)
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...3)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(severityLabels[v]).font(.system(size: 10))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                        .font(.system(size: 9))
                }
            }
            .frame(height: 120)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("尚無足夠資料")
                .font(.headline)
            Text("開始記錄排便和症狀後，統計圖表會自動出現")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
    
    // MARK: - Helpers
    
    private var xAxisStride: Int {
        switch selectedPeriod {
        case .week: return 1
        case .month: return 5
        case .quarter: return 15
        }
    }
    
    private func trendColor(_ trend: AnalyticsEngine.Trend) -> Color {
        switch trend {
        case .improving: return .green
        case .stable: return .secondary
        case .worsening: return .red
        }
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let stats: AnalyticsEngine.PeriodStats
    let summaries: [AnalyticsEngine.DailySummary]
    let period: StatsView.StatsPeriod
    
    @State private var isExporting = false
    @State private var exportedURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("匯出報告")
                    .font(.title2.weight(.semibold))
                
                Text("產生 \(period.rawValue) 的排便/症狀統計報告\n可分享給醫生作為參考")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Summary preview
                VStack(alignment: .leading, spacing: 8) {
                    reportRow("期間", "\(period.days) 天")
                    reportRow("排便總次數", "\(stats.totalBowelMovements)")
                    reportRow("平均排便", String(format: "%.1f 次/天", stats.avgBowelPerDay))
                    reportRow("Bristol 均值", String(format: "%.1f", stats.avgBristol))
                    reportRow("血便天數", "\(stats.bloodDays)")
                    reportRow("平均疼痛", String(format: "%.1f/10", stats.avgPain))
                    reportRow("腹瀉天數", "\(stats.diarrheaDays)")
                    reportRow("便秘天數", "\(stats.constipationDays)")
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.tertiarySystemGroupedBackground))
                }
                
                Spacer()
                
                Button {
                    exportAsText()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("產生文字報告")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.blue)
                    }
                    .foregroundStyle(.white)
                }
            }
            .padding(20)
            .navigationTitle("匯出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
    
    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
    }
    
    private func exportAsText() {
        let report = generateTextReport()
        let activityVC = UIActivityViewController(
            activityItems: [report],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func generateTextReport() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_TW")
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        let endDate = dateFormatter.string(from: Date.now)
        let startDate = dateFormatter.string(from: Date.now.daysAgo(period.days))
        
        var report = """
        ═══════════════════════════════
        GutTracker 腸胃健康報告
        期間：\(startDate) — \(endDate) (\(period.days)天)
        ═══════════════════════════════
        
        【排便統計】
        總次數：\(stats.totalBowelMovements) 次
        平均：\(String(format: "%.1f", stats.avgBowelPerDay)) 次/天
        Bristol 均值：\(String(format: "%.1f", stats.avgBristol))
        血便天數：\(stats.bloodDays) 天
        腹瀉天數：\(stats.diarrheaDays) 天
        便秘天數：\(stats.constipationDays) 天
        正常天數：\(stats.normalDays) 天
        
        【Bristol 分布】
        """
        
        for type in 1...7 {
            let count = stats.bristolDistribution[type] ?? 0
            let info = BristolScale.info(for: type)
            let bar = String(repeating: "█", count: min(count, 20))
            report += "\n  Type \(type) \(info.name): \(bar) \(count)次"
        }
        
        report += """
        
        
        【症狀趨勢】
        趨勢：\(stats.symptomTrend.displayName)
        平均疼痛：\(String(format: "%.1f", stats.avgPain))/10
        
        【每日明細】
        """
        
        for day in summaries.reversed().prefix(period.days) {
            if day.bowelCount > 0 || day.symptomSeverity > 0 {
                let dateStr = dateFormatter.string(from: day.date)
                let bristolStr = day.bristolTypes.map { "\($0)" }.joined(separator: ",")
                let blood = day.hasBlood ? " 🩸" : ""
                let severity = day.symptomSeverity > 0 ? " 症狀:\(severityLabels[day.symptomSeverity])" : ""
                report += "\n  \(dateStr): 排便\(day.bowelCount)次 Bristol[\(bristolStr)]\(blood)\(severity)"
            }
        }
        
        report += """
        
        
        ═══════════════════════════════
        此報告由 GutTracker App 自動產生
        僅供參考，不構成醫療建議
        ═══════════════════════════════
        """
        
        return report
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [BowelMovement.self, SymptomEntry.self, MedicationLog.self, Medication.self], inMemory: true)
}
