import Foundation

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
