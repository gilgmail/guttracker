import Foundation
import SwiftData

/// 本地統計分析引擎 - 不需要 AI API
struct AnalyticsEngine {
    
    // MARK: - Daily Summary
    
    struct DailySummary: Identifiable {
        let id: String  // date string yyyy-MM-dd
        let date: Date
        let bowelCount: Int
        let avgBristol: Double
        let bristolTypes: [Int]
        let hasBlood: Bool
        let maxPain: Int
        let symptomSeverity: Int  // 0-3 overall
        let medicationsTaken: Int
        let medicationsTotal: Int
        
        var severityLevel: OverallStatus {
            switch symptomSeverity {
            case 0: return .good
            case 1: return .mild
            case 2: return .moderate
            default: return .severe
            }
        }
        
        var medicationComplete: Bool {
            medicationsTotal > 0 && medicationsTaken >= medicationsTotal
        }
    }
    
    // MARK: - Period Stats
    
    struct PeriodStats {
        let days: Int
        let totalBowelMovements: Int
        let avgBowelPerDay: Double
        let avgBristol: Double
        let bristolDistribution: [Int: Int]  // type → count
        let bloodDays: Int
        let avgPain: Double
        let diarrheaDays: Int
        let constipationDays: Int
        let normalDays: Int
        let symptomTrend: Trend
        let bowelTrend: Trend
    }
    
    enum Trend: String {
        case improving, stable, worsening
        
        var displayName: String {
            switch self {
            case .improving: return "改善中"
            case .stable: return "穩定"
            case .worsening: return "惡化中"
            }
        }
        
        var emoji: String {
            switch self {
            case .improving: return "📈"
            case .stable: return "➡️"
            case .worsening: return "📉"
            }
        }
    }
    
    // MARK: - Compute Daily Summaries
    
    static func dailySummaries(
        bowelMovements: [BowelMovement],
        symptoms: [SymptomEntry],
        medLogs: [MedicationLog],
        totalMeds: Int,
        from startDate: Date,
        to endDate: Date
    ) -> [DailySummary] {
        let cal = Calendar.current
        var summaries: [DailySummary] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Group by date
        let bmByDate = Dictionary(grouping: bowelMovements) {
            dateFormatter.string(from: $0.timestamp)
        }
        let symByDate = Dictionary(grouping: symptoms) {
            dateFormatter.string(from: $0.timestamp)
        }
        let medByDate = Dictionary(grouping: medLogs) {
            dateFormatter.string(from: $0.timestamp)
        }
        
        var current = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        
        while current <= end {
            let key = dateFormatter.string(from: current)
            let dayBMs = bmByDate[key] ?? []
            let daySym = symByDate[key] ?? []
            let dayMeds = medByDate[key] ?? []
            
            let bristolTypes = dayBMs.map { $0.bristolType }
            let avg = bristolTypes.isEmpty ? 0 : Double(bristolTypes.reduce(0, +)) / Double(bristolTypes.count)
            
            let summary = DailySummary(
                id: key,
                date: current,
                bowelCount: dayBMs.count,
                avgBristol: avg,
                bristolTypes: bristolTypes,
                hasBlood: dayBMs.contains { $0.hasBlood },
                maxPain: dayBMs.map { $0.painLevel }.max() ?? 0,
                symptomSeverity: daySym.map { $0.overallSeverity }.max() ?? 0,
                medicationsTaken: dayMeds.filter { $0.taken }.count,
                medicationsTotal: totalMeds
            )
            summaries.append(summary)
            
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        
        return summaries
    }
    
    // MARK: - Compute Period Stats
    
    static func periodStats(from summaries: [DailySummary]) -> PeriodStats {
        guard !summaries.isEmpty else {
            return PeriodStats(
                days: 0, totalBowelMovements: 0, avgBowelPerDay: 0,
                avgBristol: 0, bristolDistribution: [:], bloodDays: 0,
                avgPain: 0, diarrheaDays: 0, constipationDays: 0,
                normalDays: 0, symptomTrend: .stable, bowelTrend: .stable
            )
        }
        
        let days = summaries.count
        let totalBM = summaries.reduce(0) { $0 + $1.bowelCount }
        let daysWithBM = summaries.filter { $0.bowelCount > 0 }
        
        let allBristol = summaries.flatMap { $0.bristolTypes }
        let avgBristol = allBristol.isEmpty ? 0 : Double(allBristol.reduce(0, +)) / Double(allBristol.count)
        
        // Bristol distribution
        var dist: [Int: Int] = [:]
        for b in allBristol { dist[b, default: 0] += 1 }
        
        // Risk days
        let bloodDays = summaries.filter { $0.hasBlood }.count
        let diarrheaDays = summaries.filter { $0.bristolTypes.contains(where: { $0 >= 6 }) }.count
        let constipationDays = summaries.filter { $0.bristolTypes.contains(where: { $0 <= 2 }) }.count
        let normalDays = summaries.filter { !$0.bristolTypes.isEmpty && $0.bristolTypes.allSatisfy { (3...5).contains($0) } }.count
        
        // Pain average
        let painDays = summaries.filter { $0.maxPain > 0 }
        let avgPain = painDays.isEmpty ? 0 : Double(painDays.reduce(0) { $0 + $1.maxPain }) / Double(painDays.count)
        
        // Trends (compare first half vs second half)
        let mid = days / 2
        let firstHalf = Array(summaries.prefix(mid))
        let secondHalf = Array(summaries.suffix(mid))
        
        let symptomTrend = computeTrend(
            firstValues: firstHalf.map { Double($0.symptomSeverity) },
            secondValues: secondHalf.map { Double($0.symptomSeverity) }
        )
        
        let bowelTrend = computeTrend(
            firstValues: firstHalf.map { Double($0.bowelCount) },
            secondValues: secondHalf.map { Double($0.bowelCount) }
        )
        
        return PeriodStats(
            days: days,
            totalBowelMovements: totalBM,
            avgBowelPerDay: daysWithBM.isEmpty ? 0 : Double(totalBM) / Double(days),
            avgBristol: avgBristol,
            bristolDistribution: dist,
            bloodDays: bloodDays,
            avgPain: avgPain,
            diarrheaDays: diarrheaDays,
            constipationDays: constipationDays,
            normalDays: normalDays,
            symptomTrend: symptomTrend,
            bowelTrend: bowelTrend
        )
    }
    
    // MARK: - Trend Calculation
    
    private static func computeTrend(firstValues: [Double], secondValues: [Double]) -> Trend {
        guard !firstValues.isEmpty && !secondValues.isEmpty else { return .stable }
        
        let firstAvg = firstValues.reduce(0, +) / Double(firstValues.count)
        let secondAvg = secondValues.reduce(0, +) / Double(secondValues.count)
        let diff = secondAvg - firstAvg
        
        // Threshold: 15% change is meaningful
        let threshold = max(firstAvg * 0.15, 0.3)
        
        if diff < -threshold { return .improving }
        if diff > threshold { return .worsening }
        return .stable
    }
    
    // MARK: - Weekly Bristol Pattern
    
    struct WeekdayPattern: Identifiable {
        let id: Int  // weekday 1=Sun ... 7=Sat
        let label: String
        let avgCount: Double
        let avgBristol: Double
    }
    
    static func weekdayPatterns(from summaries: [DailySummary]) -> [WeekdayPattern] {
        let cal = Calendar.current
        let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
        
        var grouped: [Int: [DailySummary]] = [:]
        for s in summaries {
            let wd = cal.component(.weekday, from: s.date)
            grouped[wd, default: []].append(s)
        }
        
        return (1...7).map { wd in
            let days = grouped[wd] ?? []
            let avgCount = days.isEmpty ? 0 : Double(days.reduce(0) { $0 + $1.bowelCount }) / Double(days.count)
            let allBristol = days.flatMap { $0.bristolTypes }
            let avgBristol = allBristol.isEmpty ? 0 : Double(allBristol.reduce(0, +)) / Double(allBristol.count)
            return WeekdayPattern(
                id: wd,
                label: weekdayNames[wd - 1],
                avgCount: avgCount,
                avgBristol: avgBristol
            )
        }
    }
}
