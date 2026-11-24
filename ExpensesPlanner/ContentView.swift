import SwiftUI

struct ContentView: View {
    static let title = "Activos"

    var body: some View {
        TabView {
            NavigationStack {
                AssetAccountsView()
            }
            .tabItem {
                Label("Activos", systemImage: "building.columns")
            }
            .accessibilityIdentifier("assetsTab")

            NavigationStack {
                PlanningView()
            }
            .tabItem {
                Label("Planificación", systemImage: "calendar")
            }
            .accessibilityIdentifier("planningTab")
        }
        .tint(.indigo)
    }
}

private struct PlanningView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    PeriodsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Períodos")
                            Text("Ingresos confirmados y obligaciones")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .accessibilityIdentifier("periodsNavigationLink")

                NavigationLink {
                    SavingsGoalsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Metas de ahorro")
                            Text("Objetivos y asignaciones planeadas")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "target")
                    }
                }
                .accessibilityIdentifier("goalsNavigationLink")
            } footer: {
                Text("Administra períodos, ingresos, obligaciones y metas desde Planificación.")
            }
        }
        .navigationTitle("Planificación")
    }
}

#Preview {
    ContentView()
        .modelContainer(try! FinanceModelContainer.makeContainer(inMemory: true))
}
