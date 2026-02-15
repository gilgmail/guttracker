# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project (no SPM packages, no CocoaPods). All dependencies are Apple-native frameworks.

```bash
# Build
xcodebuild -project guttracker.xcodeproj -scheme guttracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild -project guttracker.xcodeproj -scheme guttracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Install & launch on simulator
xcrun simctl install booted <path-to-.app> && xcrun simctl launch booted com.gilko.guttracker

# Open in Xcode
open guttracker.xcodeproj
```

**Requirements:** Xcode 17.0+ (iOS 26 SDK), deployment target iOS 26.0, Swift 5.9+

## Product Context

IBD (Crohn's / Ulcerative Colitis) symptom tracking app for Taiwan market. Core UX principle: **3-second recording** — one-tap Bristol Scale selection, no text input required. All UI in Traditional Chinese (繁體中文), date formatting uses `Locale("zh_TW")`.

Full spec: `GutTracker_Project_Spec.md`

## Architecture

**Pattern:** MVVM with SwiftData — views use `@Query` for reactive data and `@Environment(\.modelContext)` for mutations. No separate ViewModel classes; state is managed inline in SwiftUI views.

**Data flow:**
- `SharedContainer` configures the `ModelContainer` with App Groups (`group.com.gil.guttracker`). Falls back to default storage when App Group entitlement is unavailable (e.g. simulator without entitlements).
- `GutTrackerApp.swift` creates the container via `SharedContainer` and injects it with `.modelContainer()`.
- Views query data with `@Query` (filtered/sorted declaratively) and write via `modelContext.insert()` / `modelContext.delete()`.

**Key layers:**

| Layer | Path | Role |
|-------|------|------|
| Models | `guttracker/Models/` | SwiftData `@Model` classes: `BowelMovement`, `SymptomEntry`, `MedicationLog`, `Medication` |
| Services | `guttracker/Services/` | `AnalyticsEngine` — pure static functions for local statistics (no network calls) |
| Views | `guttracker/Views/` | SwiftUI views organized by tab: `Record/`, `Calendar/`, `Stats/`, `Settings/` |
| Utilities | `guttracker/Utilities/` | `BristolScale` (scale definitions + picker UI), `Constants`, `DateExtensions` |

**Tab structure** (`MainTabView`):
1. **Record** — daily bowel/symptom/medication entry (primary screen)
2. **Calendar** — month view with daily drill-down
3. **Stats** — charts and analytics over 7/30/90-day periods
4. **Settings** — medication management and app configuration

## Domain Concepts

- **Bristol Stool Scale**: Types 1-7 rating system. Types 1-2 = constipation risk, 3-5 = normal, 6-7 = diarrhea risk. Defined in `BristolScale.swift`.
- **Symptom severity**: 0 (none) to 3 (severe) for GI/systemic symptoms; mood is 1-5.
- **Medication catalog**: `DefaultMedications` in `MedicationLog.swift` has 13 pre-configured Taiwan IBD drugs (Pentasa, Humira, Remicade, etc.) with categories: aminosalicylate, immunomodulator, biologic, steroid, supplement.
- **AnalyticsEngine**: Computes `DailySummary`, `PeriodStats`, `Trend` (improving/stable/worsening), and `WeekdayPattern` from raw model data. All computation is local — no backend.

## Conventions

- **No external dependencies**: Only Apple frameworks (SwiftUI, SwiftData, Charts, WidgetKit, HealthKit).
- **iOS 26 TabView API**: Use `Tab("title", systemImage:, value:) { }` — the old `.tabItem` + `.tag()` pattern crashes at runtime on iOS 26.
- **Enums**: String-backed `Codable` enums with computed properties for `displayName`, `emoji`, `color`. Follow this pattern when adding new enums.
- **SwiftData default actor isolation**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set in build settings.
- **Views use `SectionCard`**: Reusable card wrapper with title, icon, and accent color for consistent section styling.
- **App Group**: `group.com.gil.guttracker` — shared SwiftData container between main app and widget. `SharedContainer` handles fallback when entitlement is absent.

## HealthKit Integration (Phase 4 — complete)

Bidirectional sync via `HealthKitService` (actor-based singleton in `Services/`):
- **Write**: BowelMovement → `HKCategoryType` mapping (Bristol 1-2 → `.constipation`, 6-7 → `.diarrhea`), pain → `.abdominalCramps`; SymptomEntry → `.abdominalCramps`, `.bloating`, `.nausea`, `.fatigue`, `.fever`
- **Read**: sleep hours (asleep core/deep/REM), step count, resting heart rate — shown in CalendarView day detail
- Metadata tagged with `"AppSource": "GutTracker"` and `HKMetadataKeyWasUserEntered: true`
- Authorization flow in SettingsView toggle — stores `@AppStorage("healthKitEnabled")`
- Sync triggered automatically on bowel/symptom recording when enabled; `healthKitSynced` flag on models prevents duplicate writes

## Widget Extension (Phase 3 — complete)

`GutTrackerWidget/` target with three sizes, sharing SwiftData via App Group:
- **Small**: read-only today summary (bowel count, Bristol types, symptom emoji, medication progress)
- **Medium**: interactive Bristol one-tap buttons (left) + medication checklist (right)
- **Large**: full daily panel — Bristol buttons + recent records + medication + blood warning
- **AppIntents**: `RecordBowelMovementIntent` (Bristol quick-log), `ToggleMedicationIntent` (medication toggle) — shared between both targets
- Timeline refreshes every 15 minutes; `WidgetCenter.shared.reloadTimelines()` called on in-app changes
- **Shared files** (target membership in both targets): Models (`SharedContainer`, `BowelMovement`, `SymptomEntry`, `MedicationLog`), Utilities (`Constants`, `DateExtensions`, `BristolScale`), Services (`AnalyticsEngine`), Intents
- **pbxproj format**: Xcode 26 uses `PBXFileSystemSynchronizedRootGroup` (objectVersion 77). Target membership is controlled via `PBXFileSystemSynchronizedBuildFileExceptionSet` with `membershipExceptions` to exclude files

## Development Phases

- Phase 1 (complete): MVP core — SwiftData models, bowel/symptom/medication CRUD, tab navigation, AnalyticsEngine
- Phase 2 (complete): Calendar view, StatsView with 3 Swift Charts (bowel frequency, Bristol distribution, symptom trend), PDF export via UIGraphicsPDFRenderer
- Phase 3 (complete): WidgetKit interactive widget — Small/Medium/Large sizes, AppIntents for Bristol recording + medication toggle
- Phase 4 (complete): HealthKit bidirectional sync — write bowel/symptom to Health, read sleep/steps/heart rate
- Phase 5 (complete): CloudKit iCloud sync, medication reminders, daily health score notification (0-100), medication edit view
