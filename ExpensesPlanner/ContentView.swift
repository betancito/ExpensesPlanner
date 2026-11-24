import SwiftUI

struct ContentView: View {
    static let title = "Mi plan"

    var body: some View {
        TabView {
            NavigationStack {
                PeriodsView()
            }
            .tabItem {
                Label("Períodos", systemImage: "calendar")
            }
            .accessibilityIdentifier("periodsTab")

            NavigationStack {
                SavingsGoalsView()
            }
            .tabItem {
                Label("Metas", systemImage: "target")
            }
            .accessibilityIdentifier("goalsTab")
        }
        .tint(.indigo)
    }
}

#Preview {
    ContentView()
        .modelContainer(try! FinanceModelContainer.makeContainer(inMemory: true))
}
