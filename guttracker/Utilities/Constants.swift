import Foundation
import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Codable {
    case cream
    case dark

    var displayName: String {
        switch self {
        case .cream: return "米色（和紙）"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .cream: return .light
        case .dark: return .dark
        }
    }

    var background: Color {
        switch self {
        case .cream: return Color(red: 0.973, green: 0.957, blue: 0.922) // #f8f4eb
        case .dark: return Color(.systemGroupedBackground)
        }
    }

    var card: Color {
        switch self {
        case .cream: return Color(red: 0.949, green: 0.929, blue: 0.894) // #f2ede4
        case .dark: return Color(.secondarySystemGroupedBackground)
        }
    }

    var elevated: Color {
        switch self {
        case .cream: return Color(red: 0.925, green: 0.906, blue: 0.867) // #ece7dd
        case .dark: return Color(.tertiarySystemGroupedBackground)
        }
    }

    var inactive: Color {
        switch self {
        case .cream: return Color(red: 0.878, green: 0.847, blue: 0.784) // #e0d8c8
        case .dark: return Color(.systemGray5)
        }
    }
}

// MARK: - Theme Environment Key

struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .cream
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - Constants

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

    // Widget Customization (stored in App Group UserDefaults)
    static let widgetBristolTypesKey = "widgetBristolTypes"   // e.g. "3,4,5,6"
    static let widgetSymptomTypesKey = "widgetSymptomTypes"   // e.g. "abdominalPain,bloating"
    static let widgetBristolCountMax = 4
    static let widgetSymptomCountMax = 3
    
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
