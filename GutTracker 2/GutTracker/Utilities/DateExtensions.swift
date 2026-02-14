import Foundation

extension Date {
    /// 今天的開始時間 00:00:00
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 今天的結束時間 23:59:59
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }
    
    /// 本週一的開始
    var startOfWeek: Date {
        let cal = Calendar.current
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: components) ?? self
    }
    
    /// N 天前
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
    
    /// 格式化為 HH:mm
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 格式化為 M月d日
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }
    
    /// 格式化為 M月d日 E
    var dateWithWeekday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: self)
    }
    
    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

extension Calendar {
    /// 兩個日期之間的天數
    func daysBetween(_ from: Date, and to: Date) -> Int {
        let fromDay = startOfDay(for: from)
        let toDay = startOfDay(for: to)
        let components = dateComponents([.day], from: fromDay, to: toDay)
        return components.day ?? 0
    }
}
