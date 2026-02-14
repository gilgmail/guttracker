import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("記錄", systemImage: "plus.circle.fill", value: 0) {
                RecordView()
            }

            Tab("日曆", systemImage: "calendar", value: 1) {
                CalendarView()
            }

            Tab("統計", systemImage: "chart.bar.fill", value: 2) {
                StatsView()
            }

            Tab("設定", systemImage: "gearshape.fill", value: 3) {
                SettingsView()
            }
        }
        .tint(.green)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            BowelMovement.self,
            SymptomEntry.self,
            MedicationLog.self,
            Medication.self,
        ], inMemory: true)
}
