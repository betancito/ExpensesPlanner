import Foundation
import SwiftData

@Model
final class BudgetPeriod {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date

    @Relationship(deleteRule: .cascade, inverse: \ConfirmedIncome.period)
    var confirmedIncomes: [ConfirmedIncome]

    @Relationship(deleteRule: .cascade, inverse: \PeriodObligation.period)
    var obligations: [PeriodObligation]

    @Relationship(deleteRule: .cascade, inverse: \CNYExpense.period)
    var expenses: [CNYExpense]

    init(id: UUID = UUID(), startDate: Date, endDate: Date) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.confirmedIncomes = []
        self.obligations = []
        self.expenses = []
    }
}

@Model
final class ConfirmedIncome {
    @Attribute(.unique) var id: UUID
    var amountCOP: Decimal
    var receivedAt: Date
    var period: BudgetPeriod?

    init(id: UUID = UUID(), amountCOP: Decimal, receivedAt: Date, period: BudgetPeriod? = nil) {
        self.id = id
        self.amountCOP = amountCOP
        self.receivedAt = receivedAt
        self.period = period
    }
}

@Model
final class PeriodObligation {
    @Attribute(.unique) var id: UUID
    var name: String
    var amountCOP: Decimal
    var period: BudgetPeriod?

    init(id: UUID = UUID(), name: String, amountCOP: Decimal, period: BudgetPeriod? = nil) {
        self.id = id
        self.name = name
        self.amountCOP = amountCOP
        self.period = period
    }
}

@Model
final class SavingsGoal {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetCOP: Decimal
    var targetDate: Date?
    var savedCOP: Decimal
    var plannedAllocationCOP: Decimal

    init(
        id: UUID = UUID(),
        name: String,
        targetCOP: Decimal,
        targetDate: Date? = nil,
        savedCOP: Decimal = .zero,
        plannedAllocationCOP: Decimal
    ) {
        self.id = id
        self.name = name
        self.targetCOP = targetCOP
        self.targetDate = targetDate
        self.savedCOP = savedCOP
        self.plannedAllocationCOP = plannedAllocationCOP
    }
}

enum ExpenseValidationError: Error, Equatable {
    case invalidExchangeRate
}

@Model
final class CNYExpense {
    @Attribute(.unique) var id: UUID
    private(set) var amountCNY: Decimal
    private(set) var exchangeRateCOPPerCNY: Decimal
    private(set) var amountCOPSnapshot: Decimal
    var timestamp: Date
    var category: String
    var note: String?
    var period: BudgetPeriod?

    init(
        id: UUID = UUID(),
        amountCNY: Decimal,
        exchangeRateCOPPerCNY: Decimal,
        timestamp: Date,
        category: String,
        note: String? = nil,
        period: BudgetPeriod? = nil
    ) throws {
        guard exchangeRateCOPPerCNY > .zero else {
            throw ExpenseValidationError.invalidExchangeRate
        }

        self.id = id
        self.amountCNY = amountCNY
        self.exchangeRateCOPPerCNY = exchangeRateCOPPerCNY
        self.amountCOPSnapshot = amountCNY * exchangeRateCOPPerCNY
        self.timestamp = timestamp
        self.category = category
        self.note = note
        self.period = period
    }
}
