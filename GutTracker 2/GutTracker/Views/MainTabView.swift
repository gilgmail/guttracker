import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .tabItem {
                    Label("記錄", systemImage: "plus.circle.fill")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("日曆", systemImage: "calendar")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
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
