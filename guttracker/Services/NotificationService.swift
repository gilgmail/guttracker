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
            content.title = "💊 用藥提醒"
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
        content.title = "📊 昨日健康評分"
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

    /// 計算昨日健康評分 (0-100)
    func computeHealthScore(
        bowelMovements: [BowelMovement],
        symptom: SymptomEntry?,
        medsTaken: Int,
        medsTotal: Int
    ) -> HealthScore {
        var score = 100
        var details: [String] = []

        // 1. 排便評分 (40 分)
        let bmCount = bowelMovements.count
        if bmCount == 0 {
            score -= 15
            details.append("無排便記錄")
        } else if bmCount > 5 {
            score -= 20
            details.append("排便頻繁(\(bmCount)次)")
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

        // 2. 症狀評分 (30 分)
        if let sym = symptom {
            score -= sym.overallSeverity * 10
            if sym.fever { details.append("發燒") }
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

        // 4. Bristol 正常度 (10 分)
        let normalBMs = bowelMovements.filter { (3...5).contains($0.bristolType) }
        if !bowelMovements.isEmpty {
            let normalRatio = Double(normalBMs.count) / Double(bowelMovements.count)
            score -= Int((1.0 - normalRatio) * 10)
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
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now))!
        let today = calendar.startOfDay(for: .now)

        let bmDescriptor = FetchDescriptor<BowelMovement>(
            predicate: #Predicate { $0.timestamp >= yesterday && $0.timestamp < today }
        )
        let symDescriptor = FetchDescriptor<SymptomEntry>(
            predicate: #Predicate { $0.timestamp >= yesterday && $0.timestamp < today }
        )
        let medLogDescriptor = FetchDescriptor<MedicationLog>(
            predicate: #Predicate { $0.timestamp >= yesterday && $0.timestamp < today }
        )
        let medDescriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.isActive == true }
        )

        let bms = (try? context.fetch(bmDescriptor)) ?? []
        let symptom = try? context.fetch(symDescriptor).first
        let medLogs = (try? context.fetch(medLogDescriptor)) ?? []
        let totalMeds = (try? context.fetch(medDescriptor).count) ?? 0

        let result = computeHealthScore(
            bowelMovements: bms,
            symptom: symptom,
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
        case .excellent: return "非常好"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "需注意"
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
