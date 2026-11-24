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

    #if DEBUG
    static func deleteAllLocalData(in context: ModelContext) throws {
        try context.delete(model: BudgetPeriod.self)
        try context.delete(model: ConfirmedIncome.self)
        try context.delete(model: PeriodObligation.self)
        try context.delete(model: SavingsGoal.self)
        try context.delete(model: CNYExpense.self)
        try context.delete(model: ExchangeRateSnapshot.self)
        try context.save()
    }
    #endif
}
