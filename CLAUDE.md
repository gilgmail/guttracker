# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project (no SPM packages, no CocoaPods). All dependencies are Apple-native frameworks.

```bash
# Build
xcodebuild -project guttracker.xcodeproj -scheme guttracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project guttracker.xcodeproj -scheme guttracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test

# Open in Xcode
open guttracker.xcodeproj
```

**Requirements:** Xcode 16.0+, iOS 17.0+ deployment target, Swift 5.9+

## Product Context

IBD (Crohn's / Ulcerative Colitis) symptom tracking app for Taiwan market. Core UX principle: **3-second recording** — one-tap Bristol Scale selection, no text input required. All UI in Traditional Chinese (繁體中文), date formatting uses `Locale("zh_TW")`.

Full spec: `guttracker_project_spec.md`

## Architecture

**Pattern:** MVVM with SwiftData — views use `@Query` for reactive data and `@Environment(\.modelContext)` for mutations. No separate ViewModel classes; state is managed inline in SwiftUI views.

**Data flow:**
- `SharedContainer` configures the `ModelContainer` with App Groups (`group.com.gil.guttracker`) so the main app and widget extension share the same SwiftData store.
- `GutTrackerApp.swift` creates the container and injects it via `.modelContainer()`.
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
- **Enums**: String-backed `Codable` enums with computed properties for `displayName`, `emoji`, `color`. Follow this pattern when adding new enums.
- **SwiftData default actor isolation**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set in build settings.
- **Views use `SectionCard`**: Reusable card wrapper with title, icon, and accent color for consistent section styling.
- **App Group**: `group.com.gil.guttracker` — shared SwiftData container between main app and widget. All model changes must remain compatible with `SharedContainer`.

## HealthKit Integration (Phase 4)

Planned bidirectional sync via `HealthKitService` (actor-based singleton):
- **Write**: BowelMovement → `HKCategoryType` mapping (Bristol 1-2 → `.constipation`, 6-7 → `.diarrhea`), symptoms → `.abdominalCramps`, `.bloating`, `.nausea`, `.fatigue`, `.fever`
- **Read**: sleep analysis, step count, heart rate, body mass
- Metadata tagged with `"AppSource": "GutTracker"` and `HKMetadataKeyWasUserEntered: true`

## Widget Extension (Phase 3)

Planned `GutTrackerWidget/` target with three sizes:
- **Small**: read-only today summary (bowel count, status)
- **Medium**: Bristol one-tap recording buttons + medication status (Interactive Widget via `AppIntent`)
- **Large**: full daily panel with record list
- Key intents: `RecordBowelMovementIntent` (Bristol quick-log), `ToggleMedicationIntent` (medication check-off)
- Timeline refreshes every 15 minutes

## Development Phases

- Phase 1 (complete): MVP core — SwiftData models + bowel/symptom/medication CRUD + tab navigation
- Phase 2: Calendar drill-down + Swift Charts statistics + PDF export
- Phase 3: WidgetKit interactive widget for quick Bristol recording
- Phase 4: HealthKit bidirectional sync
- Phase 5: CloudKit iCloud sync + medication reminders (Local Notification) + UI polish
