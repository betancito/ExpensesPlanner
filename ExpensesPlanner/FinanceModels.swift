import Foundation
import SwiftData

enum AssetAccountType: String, Codable, CaseIterable, Identifiable {
    case checking
    case savings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .checking:
            return "Corriente"
        case .savings:
            return "Ahorros"
        }
    }

    var explanation: String {
        switch self {
        case .checking:
            return "Dinero disponible para el uso diario."
        case .savings:
            return "Dinero acumulado como ahorro."
        }
    }
}

enum AssetCurrency: String, Codable, CaseIterable, Identifiable {
    case cop = "COP"
    case cny = "CNY"

    var id: String { rawValue }
}

@Model
final class AssetAccount {
    @Attribute(.unique) var id: UUID
    var name: String
    private(set) var typeRawValue: String
    private(set) var currencyRawValue: String
    var balance: Decimal

    var type: AssetAccountType {
        get { AssetAccountType(rawValue: typeRawValue) ?? .checking }
        set { typeRawValue = newValue.rawValue }
    }

    var currency: AssetCurrency {
        get { AssetCurrency(rawValue: currencyRawValue) ?? .cop }
        set { currencyRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: AssetAccountType,
        currency: AssetCurrency,
        balance: Decimal
    ) {
        self.id = id
        self.name = name
        self.typeRawValue = type.rawValue
        self.currencyRawValue = currency.rawValue
        self.balance = balance
    }
}

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
