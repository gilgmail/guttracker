import Foundation
import SwiftUI

enum Constants {
    static let appName = "GutTracker"
    static let appGroupIdentifier = "group.com.gil.guttracker"
    static let bundleIdentifier = "com.gil.guttracker"
    
    // Bristol Scale
    static let bristolMinType = 1
    static let bristolMaxType = 7
    static let bristolNormalRange = 3...5
    
    // Severity
    static let maxSeverity = 3
    static let maxPainLevel = 10
    
    // Widget
    static let widgetKind = "GutTrackerWidget"
    static let widgetRefreshIntervalMinutes = 15
    
    // Data
    static let maxRecentRecords = 50
    static let defaultAnalysisDays = 30
}

// MARK: - Zen Design Tokens

enum ZenColors {
    /// Bristol types 1-2 (constipation)
    static let bristolHard = Color(red: 0.545, green: 0.420, blue: 0.333)
    /// Bristol types 3-5 (normal)
    static let bristolNormal = Color(red: 0.290, green: 0.486, blue: 0.349)
    /// Bristol types 6-7 (diarrhea)
    static let bristolSoft = Color(red: 0.420, green: 0.486, blue: 0.545)
    /// Symptom active accent
    static let amber = Color(red: 0.769, green: 0.584, blue: 0.416)

    static func bristolZone(for type: Int) -> Color {
        switch type {
        case 1...2: return bristolHard
        case 3...5: return bristolNormal
        case 6...7: return bristolSoft
        default: return bristolNormal
        }
    }
}
