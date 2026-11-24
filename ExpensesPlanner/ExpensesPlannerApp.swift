import SwiftData
import SwiftUI

@main
struct ExpensesPlannerApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try FinanceModelContainer.makeContainer()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-reset-local-data-for-ui-tests") {
                let context = ModelContext(container)
                try FinanceModelContainer.deleteAllLocalData(in: context)
            }
            #endif
        } catch {
            fatalError("No se pudo abrir el almacenamiento local: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
