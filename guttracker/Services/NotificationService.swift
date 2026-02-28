import UserNotifications
import SwiftData

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // MARK: - Reschedule All

    func rescheduleAll(container: ModelContainer) {
        Task {
            let enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            guard enabled else {
                center.removeAllPendingNotificationRequests()
                return
            }

            let granted = (try? await requestAuthorization()) ?? false
            guard granted else { return }

            center.removeAllPendingNotificationRequests()

            let context = ModelContext(container)
            scheduleMedicationReminders(context: context)
            scheduleDailyHealthScore(context: context)
        }
    }

    // MARK: - Medication Reminders

    private func scheduleMedicationReminders(context: ModelContext) {
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive == true && $0.reminderEnabled == true }
        )
        guard let meds = try? context.fetch(descriptor) else { return }

        for med in meds {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "💊 用藥提醒")
            content.body = "\(med.name) \(med.defaultDosage)"
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"

            var dateComponents = DateComponents()
            dateComponents.hour = med.reminderHour
            dateComponents.minute = med.reminderMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "med-\(med.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    // MARK: - Daily Health Score Notification

    private func scheduleDailyHealthScore(context: ModelContext) {
        let scoreEnabled = UserDefaults.standard.bool(forKey: "dailyScoreEnabled")
        guard scoreEnabled else { return }

        let hour = UserDefaults.standard.integer(forKey: "dailyScoreHour")
        let minute = UserDefaults.standard.integer(forKey: "dailyScoreMinute")

        let content = UNMutableNotificationContent()
        content.title = String(localized: "📊 昨日健康評分")
        content.body = computeYesterdayScoreSummary(context: context)
        content.sound = .default
        content.categoryIdentifier = "DAILY_SCORE"

        var dateComponents = DateComponents()
        dateComponents.hour = hour == 0 ? 9 : hour // default 9:00
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-health-score",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Health Score Computation

    /// 計算健康評分 (0-100)
    /// - Parameters:
    ///   - previousSymptom: 前一日症狀記錄，用於計算改善/惡化趨勢
    func computeHealthScore(
        bowelMovements: [BowelMovement],
        symptom: SymptomEntry?,
        previousSymptom: SymptomEntry? = nil,
        medsTaken: Int,
        medsTotal: Int
    ) -> HealthScore {
        var score = 100
        var details: [String] = []

        // 1. 排便評分 — 頻率梯度 + 異常 + 血便 + 疼痛
        let bmCount = bowelMovements.count
        if bmCount == 0 {
            score -= 15
            details.append("無排便記錄")
        } else if bmCount >= 6 {
            score -= 20
            details.append("排便頻繁(\(bmCount)次)")
        } else if bmCount >= 4 {
            score -= 8
            details.append("排便偏多(\(bmCount)次)")
        }

        let abnormalBMs = bowelMovements.filter { $0.bristolType <= 2 || $0.bristolType >= 6 }
        score -= abnormalBMs.count * 8

        if bowelMovements.contains(where: { $0.hasBlood }) {
            score -= 15
            details.append("有血便")
        }

        let avgPain = bowelMovements.isEmpty ? 0 :
            bowelMovements.reduce(0) { $0 + $1.painLevel } / bowelMovements.count
        if avgPain > 3 {
            score -= min(avgPain * 2, 15)
        }

        // 2. 症狀評分 — 峰值 + 負擔 + 高危 + 趨勢 + 睡眠/情緒
        if let sym = symptom {
            // 基礎：最高嚴重度（峰值）
            score -= sym.overallSeverity * 5       // max -15

            // 整體負擔（加總），捕捉多重輕微症狀
            score -= min(sym.symptomBurden / 3, 5)  // max -5

            // 高危症狀
            if sym.fever {
                score -= 5
                details.append("發燒")
            }

            // 趨勢比較：與前日症狀嚴重度對比
            if let prev = previousSymptom {
                let delta = sym.overallSeverity - prev.overallSeverity
                if delta < 0 {
                    score += 5    // 改善加分
                    details.append("症狀改善中")
                } else if delta > 0 {
                    score -= 5    // 惡化扣分
                    details.append("症狀惡化")
                }
            }

            // 睡眠品質差加扣
            if sym.sleepQuality >= 2 {
                score -= 3
            }

            // 情緒良好小幅加分
            if sym.mood >= 4 {
                score += 2
            }
        } else {
            // 症狀未記錄：有排便記錄時輕微扣分
            if !bowelMovements.isEmpty {
                score -= 5
                details.append("症狀未記錄")
            }
        }

        // 3. 用藥完成度 (20 分)
        if medsTotal > 0 {
            let completion = Double(medsTaken) / Double(medsTotal)
            if completion < 1.0 {
                score -= Int((1.0 - completion) * 20)
                if completion == 0 {
                    details.append("未服藥")
                }
            }
        }

        // 4. Bristol 正常度 — 獎勵制（避免與 Section 1 重複扣分）
        if !bowelMovements.isEmpty {
            let allNormal = bowelMovements.allSatisfy { (3...5).contains($0.bristolType) }
            if allNormal {
                score += 5
            }
        }

        score = max(0, min(100, score))

        let level: HealthScoreLevel
        switch score {
        case 80...100: level = .excellent
        case 60..<80: level = .good
        case 40..<60: level = .fair
        default: level = .poor
        }

        return HealthScore(score: score, level: level, details: details)
    }

    private func computeYesterdayScoreSummary(context: ModelContext) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let bmDescriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate { $0.timestamp >= yesterday && $0.timestamp < today }
        )
        let symDescriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= yesterday && $0.timestamp < today }
        )
        let prevSymDescriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= twoDaysAgo && $0.timestamp < yesterday }
        )
        let medLogDescriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.timestamp >= yesterday && $0.timestamp < today }
        )
        let medDescriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive == true }
        )

        let bms = (try? context.fetch(bmDescriptor)) ?? []
        let symptom = try? context.fetch(symDescriptor).first
        let previousSymptom = try? context.fetch(prevSymDescriptor).first
        let medLogs = (try? context.fetch(medLogDescriptor)) ?? []
        let totalMeds = (try? context.fetch(medDescriptor).count) ?? 0

        let result = computeHealthScore(
            bowelMovements: bms,
            symptom: symptom,
            previousSymptom: previousSymptom,
            medsTaken: medLogs.count,
            medsTotal: totalMeds
        )

        var body = "\(result.level.emoji) \(result.score)分 — \(result.level.displayName)"
        if !result.details.isEmpty {
            body += "\n" + result.details.joined(separator: "、")
        }
        return body
    }
}

// MARK: - Health Score Types

struct HealthScore {
    let score: Int       // 0-100
    let level: HealthScoreLevel
    let details: [String]
}

enum HealthScoreLevel {
    case excellent, good, fair, poor

    var displayName: String {
        switch self {
        case .excellent: return String(localized: "非常好")
        case .good: return String(localized: "良好")
        case .fair: return String(localized: "一般")
        case .poor: return String(localized: "需注意")
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "😊"
        case .fair: return "😐"
        case .poor: return "⚠️"
        }
    }

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "green"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
}
