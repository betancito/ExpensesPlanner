import Foundation

struct BudgetSummary: Equatable {
    let confirmedIncomeCOP: Decimal
    let obligationsCOP: Decimal
    let savingsAllocationCOP: Decimal
    let flexibleSpendingCOP: Decimal
    let recordedExpensesCOP: Decimal
    let remainingCOP: Decimal
    let inclusiveDaysRemaining: Int
    let dailyAllowanceCNY: Decimal
    let isOverBudget: Bool
}

enum BudgetEngineError: Error, Equatable {
    case invalidPeriod
    case invalidPlanningExchangeRate
}

enum BudgetEngine {
    static func calculate(
        period: BudgetPeriod,
        savingsGoals: [SavingsGoal] = [],
        planningCOPPerCNY: Decimal,
        on date: Date = .now,
        calendar: Calendar = .current
    ) throws -> BudgetSummary {
        let periodStart = calendar.startOfDay(for: period.startDate)
        let periodEnd = calendar.startOfDay(for: period.endDate)
        guard periodStart <= periodEnd else {
            throw BudgetEngineError.invalidPeriod
        }
        guard planningCOPPerCNY > .zero else {
            throw BudgetEngineError.invalidPlanningExchangeRate
        }

        let confirmedIncome = period.confirmedIncomes.reduce(Decimal.zero) { $0 + $1.amountCOP }
        let obligations = period.obligations.reduce(Decimal.zero) { $0 + $1.amountCOP }
        let savingsAllocation = savingsGoals.reduce(Decimal.zero) { $0 + $1.plannedAllocationCOP }
        let expenses = period.expenses.reduce(Decimal.zero) { $0 + $1.amountCOPSnapshot }
        let flexibleSpending = confirmedIncome - obligations - savingsAllocation
        let remaining = flexibleSpending - expenses
        let daysRemaining = inclusiveDaysRemaining(
            periodStart: periodStart,
            periodEnd: periodEnd,
            on: date,
            calendar: calendar
        )
        let dailyAllowance: Decimal

        if remaining > .zero, daysRemaining > 0 {
            dailyAllowance = remaining / Decimal(daysRemaining) / planningCOPPerCNY
        } else {
            dailyAllowance = .zero
        }

        return BudgetSummary(
            confirmedIncomeCOP: confirmedIncome,
            obligationsCOP: obligations,
            savingsAllocationCOP: savingsAllocation,
            flexibleSpendingCOP: flexibleSpending,
            recordedExpensesCOP: expenses,
            remainingCOP: remaining,
            inclusiveDaysRemaining: daysRemaining,
            dailyAllowanceCNY: dailyAllowance,
            isOverBudget: remaining < .zero
        )
    }

    private static func inclusiveDaysRemaining(
        periodStart: Date,
        periodEnd: Date,
        on date: Date,
        calendar: Calendar
    ) -> Int {
        let firstRemainingDay = max(periodStart, calendar.startOfDay(for: date))
        guard firstRemainingDay <= periodEnd else {
            return 0
        }

        let elapsedDays = calendar.dateComponents(
            [.day],
            from: firstRemainingDay,
            to: periodEnd
        ).day ?? 0
        return elapsedDays + 1
    }
}
