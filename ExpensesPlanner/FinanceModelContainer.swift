import SwiftData

enum FinanceModelContainer {
    static let modelTypes: [any PersistentModel.Type] = [
        BudgetPeriod.self,
        ConfirmedIncome.self,
        PeriodObligation.self,
        SavingsGoal.self,
        CNYExpense.self,
        ExchangeRateSnapshot.self,
    ]

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(modelTypes)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
