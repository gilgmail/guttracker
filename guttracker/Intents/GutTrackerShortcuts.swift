import AppIntents

struct GutTrackerShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordBowelMovementIntent(),
            phrases: ["用 \(.applicationName) 記錄排便", "用 \(.applicationName) 記錄今天排便"],
            shortTitle: "記錄排便",
            systemImageName: "toilet.fill"
        )
        AppShortcut(
            intent: RecordBowelMovementIntent(bristolType: 7),
            phrases: ["用 \(.applicationName) 記錄腹瀉"],
            shortTitle: "記錄腹瀉",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: ToggleSymptomIntent(symptomType: SymptomType.abdominalPain),
            phrases: ["用 \(.applicationName) 記錄腹痛"],
            shortTitle: "記錄腹痛",
            systemImageName: "waveform.path.ecg"
        )
        AppShortcut(
            intent: ToggleSymptomIntent(symptomType: SymptomType.bloating),
            phrases: ["用 \(.applicationName) 記錄腹脹"],
            shortTitle: "記錄腹脹",
            systemImageName: "aqi.medium"
        )
        AppShortcut(
            intent: ToggleSymptomIntent(symptomType: SymptomType.nausea),
            phrases: ["用 \(.applicationName) 記錄噁心"],
            shortTitle: "記錄噁心",
            systemImageName: "face.smiling.inverse"
        )
        AppShortcut(
            intent: ToggleSymptomIntent(symptomType: SymptomType.fatigue),
            phrases: ["用 \(.applicationName) 記錄疲倦"],
            shortTitle: "記錄疲倦",
            systemImageName: "zzz"
        )
        AppShortcut(
            intent: ToggleSymptomIntent(symptomType: SymptomType.cramping),
            phrases: ["用 \(.applicationName) 記錄絞痛"],
            shortTitle: "記錄絞痛",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: ToggleSymptomIntent(symptomType: SymptomType.fever),
            phrases: ["用 \(.applicationName) 記錄發燒"],
            shortTitle: "記錄發燒",
            systemImageName: "thermometer.medium"
        )
    }
}
