import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.appTheme) private var theme
    @Query(sort: \BowelMovement.timestamp) private var allBMs: [BowelMovement]
    @Query(sort: \SymptomEntry.timestamp) private var allSymptoms: [SymptomEntry]
    @Query(sort: \MedicationLog.timestamp) private var allMedLogs: [MedicationLog]
    @Query(filter: #Predicate<Medication> { $0.isActive == true })
    private var activeMeds: [Medication]
    
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var showExport: Bool = false
    @State private var chartsAppeared: Bool = false
    
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

        var displayName: String {
            switch self {
            case .week: return String(localized: "7天")
            case .month: return String(localized: "30天")
            case .quarter: return String(localized: "90天")
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
                            .opacity(chartsAppeared ? 1 : 0)
                            .offset(y: chartsAppeared ? 0 : 20)
                        bristolDistributionChart
                            .opacity(chartsAppeared ? 1 : 0)
                            .offset(y: chartsAppeared ? 0 : 20)
                        symptomTrendChart
                            .opacity(chartsAppeared ? 1 : 0)
                            .offset(y: chartsAppeared ? 0 : 20)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(theme.background)
            .navigationTitle("統計")
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    chartsAppeared = true
                }
            }
            .onChange(of: selectedPeriod) {
                chartsAppeared = false
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    chartsAppeared = true
                }
            }
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
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            summaryCard(
                title: String(localized: "平均排便"),
                value: String(format: "%.1f", stats.avgBowelPerDay),
                unit: String(localized: "次/天"),
                icon: "💩",
                trend: stats.bowelTrend
            )
            summaryCard(
                title: String(localized: "Bristol 均值"),
                value: String(format: "%.1f", stats.avgBristol),
                unit: "",
                icon: BristolScale.info(for: Int(stats.avgBristol.rounded())).emoji,
                trend: nil
            )
            summaryCard(
                title: String(localized: "血便天數"),
                value: "\(stats.bloodDays)",
                unit: String(localized: "天"),
                icon: "🩸",
                trend: nil,
                isWarning: stats.bloodDays > 0
            )
            summaryCard(
                title: String(localized: "平均疼痛"),
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
                .fill(theme.card)
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
                .fill(theme.card)
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
                riskBadge(label: String(localized: "便秘"), count: stats.constipationDays, color: .orange, icon: "🪨")
                riskBadge(label: String(localized: "正常"), count: stats.normalDays, color: .green, icon: "🍌")
                riskBadge(label: String(localized: "腹瀉"), count: stats.diarrheaDays, color: .red, icon: "💧")
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.card)
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
                            Text(severityLabel(for: v)).font(.system(size: 10))
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
                .fill(theme.card)
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
    @Environment(\.appTheme) private var theme
    let stats: AnalyticsEngine.PeriodStats
    let summaries: [AnalyticsEngine.DailySummary]
    let period: StatsView.StatsPeriod

    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("匯出報告")
                    .font(.title2.weight(.semibold))

                Text("產生 \(period.displayName) 的排便/症狀統計報告\n可分享給醫生作為參考")
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
                        .fill(theme.elevated)
                }

                Spacer()

                Button {
                    exportAsPDF()
                } label: {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("產生 PDF 報告")
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

    // MARK: - PDF Export

    private func exportAsPDF() {
        let pdfData = PDFReportGenerator.generate(
            stats: stats,
            summaries: summaries,
            period: period
        )

        let fileName = "GutTracker_報告_\(period.rawValue).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)

        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - PDF Report Generator

private enum PDFReportGenerator {

    // A4 page size in points (595 x 842)
    static let pageWidth: CGFloat = 595
    static let pageHeight: CGFloat = 842
    static let margin: CGFloat = 40
    static let contentWidth: CGFloat = 595 - 80 // pageWidth - 2*margin

    static func generate(
        stats: AnalyticsEngine.PeriodStats,
        summaries: [AnalyticsEngine.DailySummary],
        period: StatsView.StatsPeriod
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let endDate = dateFormatter.string(from: Date.now)
        let startDate = dateFormatter.string(from: Date.now.daysAgo(period.days))

        return renderer.pdfData { context in
            context.beginPage()
            var y = margin

            // === Header ===
            y = drawHeader(y: y, startDate: startDate, endDate: endDate, days: period.days)

            // === Summary Stats ===
            y = drawSectionTitle(String(localized: "排便統計"), y: y)
            y = drawStatsTable(stats: stats, y: y)

            // === Bristol Distribution ===
            y += 16
            y = drawSectionTitle(String(localized: "Bristol 分布"), y: y)
            y = drawBristolDistribution(stats: stats, y: y)

            // === Symptom Trend ===
            y += 16
            y = drawSectionTitle(String(localized: "症狀趨勢"), y: y)
            y = drawSymptomSummary(stats: stats, y: y)

            // === Daily Detail ===
            y += 16
            y = drawSectionTitle(String(localized: "每日明細"), y: y)

            let activeDays = summaries.reversed().filter { $0.bowelCount > 0 || $0.symptomSeverity > 0 }
            for day in activeDays {
                // Check if we need a new page
                if y > pageHeight - margin - 20 {
                    drawFooter()
                    context.beginPage()
                    y = margin
                }
                y = drawDailyRow(day: day, dateFormatter: dateFormatter, y: y)
            }

            // === Footer ===
            drawFooter()
        }
    }

    // MARK: - Drawing Helpers

    private static func drawHeader(y: CGFloat, startDate: String, endDate: String, days: Int) -> CGFloat {
        var currentY = y

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let title = String(localized: "GutTracker 腸胃健康報告")
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttrs)
        currentY += 32

        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let subtitle = String(localized: "期間：") + "\(startDate) — \(endDate)（\(days) " + String(localized: "天") + "）"
        subtitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subtitleAttrs)
        currentY += 22

        // Divider line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: currentY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        UIColor.separator.setStroke()
        path.lineWidth = 1
        path.stroke()
        currentY += 16

        return currentY
    }

    private static func drawSectionTitle(_ title: String, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
        return y + 26
    }

    private static func drawStatsTable(stats: AnalyticsEngine.PeriodStats, y: CGFloat) -> CGFloat {
        let rows: [(String, String)] = [
            (String(localized: "排便總次數"), "\(stats.totalBowelMovements) " + String(localized: "次")),
            (String(localized: "平均排便"), String(format: "%.1f " + String(localized: "次/天"), stats.avgBowelPerDay)),
            (String(localized: "Bristol 均值"), String(format: "%.1f", stats.avgBristol)),
            (String(localized: "血便天數"), "\(stats.bloodDays) " + String(localized: "天")),
            (String(localized: "平均疼痛"), String(format: "%.1f / 10", stats.avgPain)),
            (String(localized: "腹瀉天數"), "\(stats.diarrheaDays) " + String(localized: "天")),
            (String(localized: "便秘天數"), "\(stats.constipationDays) " + String(localized: "天")),
            (String(localized: "正常天數"), "\(stats.normalDays) " + String(localized: "天")),
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.label
        ]

        var currentY = y
        let colWidth = contentWidth / 2

        for (i, row) in rows.enumerated() {
            let col = CGFloat(i % 2)
            let x = margin + col * colWidth

            // Alternate row background
            if i % 2 == 0 && i % 4 < 2 {
                let bgRect = CGRect(x: margin, y: currentY - 2, width: contentWidth, height: 20)
                UIColor.systemGray6.setFill()
                UIBezierPath(roundedRect: bgRect, cornerRadius: 3).fill()
            }

            row.0.draw(at: CGPoint(x: x, y: currentY), withAttributes: labelAttrs)
            row.1.draw(at: CGPoint(x: x + 90, y: currentY), withAttributes: valueAttrs)

            if i % 2 == 1 { currentY += 22 }
        }
        if rows.count % 2 == 1 { currentY += 22 }

        return currentY
    }

    private static func drawBristolDistribution(stats: AnalyticsEngine.PeriodStats, y: CGFloat) -> CGFloat {
        var currentY = y
        let maxCount = stats.bristolDistribution.values.max() ?? 1
        let barMaxWidth: CGFloat = contentWidth - 140

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        for type in 1...7 {
            let count = stats.bristolDistribution[type] ?? 0
            let info = BristolScale.info(for: type)
            let label = "Type \(type) \(info.name)"
            label.draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)

            // Bar
            let barWidth = maxCount > 0 ? barMaxWidth * CGFloat(count) / CGFloat(maxCount) : 0
            if barWidth > 0 {
                let barRect = CGRect(x: margin + 100, y: currentY + 2, width: barWidth, height: 12)
                let barColor = bristolUIColor(for: type)
                barColor.setFill()
                UIBezierPath(roundedRect: barRect, cornerRadius: 3).fill()
            }

            // Count
            "\(count)".draw(at: CGPoint(x: margin + 106 + barWidth, y: currentY), withAttributes: countAttrs)

            currentY += 20
        }

        return currentY
    }

    private static func drawSymptomSummary(stats: AnalyticsEngine.PeriodStats, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.label
        ]

        var currentY = y
        let trendText = String(localized: "趨勢：") + stats.symptomTrend.displayName
        trendText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
        currentY += 20

        let painText = String(localized: "平均疼痛：") + String(format: "%.1f / 10", stats.avgPain)
        painText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
        currentY += 20

        let bowelTrendText = String(localized: "排便趨勢：") + stats.bowelTrend.displayName
        bowelTrendText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
        currentY += 20

        return currentY
    }

    private static func drawDailyRow(
        day: AnalyticsEngine.DailySummary,
        dateFormatter: DateFormatter,
        y: CGFloat
    ) -> CGFloat {
        let dateStr = dateFormatter.string(from: day.date)
        let bristolStr = day.bristolTypes.map { "\($0)" }.joined(separator: ", ")
        let blood = day.hasBlood ? " " + String(localized: "[血便]") : ""
        let severity = day.symptomSeverity > 0 ? "  " + String(localized: "症狀:") + " \(severityLabel(for: day.symptomSeverity))" : ""
        let medInfo = day.medicationsTotal > 0 ? "  " + String(localized: "用藥:") + " \(day.medicationsTaken)/\(day.medicationsTotal)" : ""

        let text = "\(dateStr)  " + String(localized: "排便") + " \(day.bowelCount) " + String(localized: "次") + "  Bristol [\(bristolStr)]\(blood)\(severity)\(medInfo)"

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: day.hasBlood ? UIColor.systemRed : UIColor.label
        ]
        text.draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)

        return y + 16
    }

    private static func drawFooter() {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let footer = String(localized: "此報告由 GutTracker App 自動產生，僅供參考，不構成醫療建議")
        footer.draw(at: CGPoint(x: margin, y: pageHeight - margin + 8), withAttributes: footerAttrs)
    }

    private static func bristolUIColor(for type: Int) -> UIColor {
        switch type {
        case 1: return UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        case 2: return UIColor(red: 0.63, green: 0.32, blue: 0.18, alpha: 1)
        case 3: return UIColor(red: 0.42, green: 0.56, blue: 0.14, alpha: 1)
        case 4: return UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1)
        case 5: return UIColor(red: 0.27, green: 0.51, blue: 0.71, alpha: 1)
        case 6: return UIColor(red: 0.82, green: 0.41, blue: 0.12, alpha: 1)
        case 7: return UIColor(red: 0.80, green: 0.36, blue: 0.36, alpha: 1)
        default: return .systemGray
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [BowelMovement.self, SymptomEntry.self, MedicationLog.self, Medication.self], inMemory: true)
}
