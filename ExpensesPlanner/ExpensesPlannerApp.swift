import SwiftData
import SwiftUI

@main
struct ExpensesPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FinanceModelContainer.modelTypes)
    }
}
