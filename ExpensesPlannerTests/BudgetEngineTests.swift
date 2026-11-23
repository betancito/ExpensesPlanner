import Foundation
import XCTest
@testable import ExpensesPlanner

final class BudgetEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testCalculatesFlexibleSpendingRemainingAndDailyAllowanceFromStoredSnapshots() throws {
        let period = makePeriod(startDay: 1, endDay: 10)
        period.confirmedIncomes = [
            ConfirmedIncome(amountCOP: Decimal(2_000_000), receivedAt: date(day: 1)),
            ConfirmedIncome(amountCOP: Decimal(500_000), receivedAt: date(day: 2)),
        ]
        period.obligations = [
            PeriodObligation(name: "Rent", amountCOP: Decimal(600_000)),
            PeriodObligation(name: "Utilities", amountCOP: Decimal(100_000)),
        ]
        period.expenses = [
            try CNYExpense(
                amountCNY: Decimal(200),
                exchangeRateCOPPerCNY: Decimal(4_000),
                timestamp: date(day: 3),
                category: "Food"
            ),
            try CNYExpense(
                amountCNY: Decimal(100),
                exchangeRateCOPPerCNY: Decimal(5_000),
                timestamp: date(day: 4),
                category: "Transport"
            ),
        ]
        let savingsGoals = [
            SavingsGoal(name: "Travel", targetCOP: Decimal(2_000_000), plannedAllocationCOP: Decimal(200_000)),
            SavingsGoal(name: "Emergency", targetCOP: Decimal(3_000_000), plannedAllocationCOP: Decimal(100_000)),
        ]

        let summary = try BudgetEngine.calculate(
            period: period,
            savingsGoals: savingsGoals,
            planningCOPPerCNY: Decimal(5_000),
            on: date(day: 6),
            calendar: calendar
        )

        XCTAssertEqual(summary.confirmedIncomeCOP, Decimal(2_500_000))
        XCTAssertEqual(summary.obligationsCOP, Decimal(700_000))
        XCTAssertEqual(summary.savingsAllocationCOP, Decimal(300_000))
        XCTAssertEqual(summary.flexibleSpendingCOP, Decimal(1_500_000))
        XCTAssertEqual(summary.recordedExpensesCOP, Decimal(1_300_000))
        XCTAssertEqual(summary.remainingCOP, Decimal(200_000))
        XCTAssertEqual(summary.inclusiveDaysRemaining, 5)
        XCTAssertEqual(summary.dailyAllowanceCNY, Decimal(8))
        XCTAssertFalse(summary.isOverBudget)
    }

    func testNoConfirmedIncomeMeansNoSpendableFunds() throws {
        let period = makePeriod(startDay: 1, endDay: 10)
        period.obligations = [PeriodObligation(name: "Rent", amountCOP: Decimal(1))]

        let summary = try BudgetEngine.calculate(
            period: period,
            planningCOPPerCNY: Decimal(5_000),
            on: date(day: 1),
            calendar: calendar
        )

        XCTAssertEqual(summary.confirmedIncomeCOP, .zero)
        XCTAssertEqual(summary.flexibleSpendingCOP, Decimal(-1))
        XCTAssertEqual(summary.dailyAllowanceCNY, .zero)
        XCTAssertTrue(summary.isOverBudget)
    }

    func testInclusiveDaysRemainingCoversBeforePeriodFirstDayFinalDayAndAfterPeriod() throws {
        let period = makePeriod(startDay: 1, endDay: 10)
        period.confirmedIncomes = [ConfirmedIncome(amountCOP: Decimal(1_000_000), receivedAt: date(day: 1))]

        let beforePeriod = try calculate(period: period, on: date(month: 12, day: 31, year: 2025))
        let firstDay = try calculate(period: period, on: date(day: 1, hour: 23))
        let finalDay = try calculate(period: period, on: date(day: 10, hour: 23))
        let afterPeriod = try calculate(period: period, on: date(day: 11))

        XCTAssertEqual(beforePeriod.inclusiveDaysRemaining, 10)
        XCTAssertEqual(firstDay.inclusiveDaysRemaining, 10)
        XCTAssertEqual(finalDay.inclusiveDaysRemaining, 1)
        XCTAssertEqual(finalDay.dailyAllowanceCNY, Decimal(200))
        XCTAssertEqual(afterPeriod.inclusiveDaysRemaining, 0)
        XCTAssertEqual(afterPeriod.dailyAllowanceCNY, .zero)
    }

    func testZeroRemainingFundsHasZeroAllowanceWithoutOverBudgetFlag() throws {
        let period = makePeriod(startDay: 1, endDay: 1)
        period.confirmedIncomes = [ConfirmedIncome(amountCOP: Decimal(100), receivedAt: date(day: 1))]
        period.expenses = [
            try CNYExpense(
                amountCNY: Decimal(1),
                exchangeRateCOPPerCNY: Decimal(100),
                timestamp: date(day: 1),
                category: "Food"
            ),
        ]

        let summary = try calculate(period: period, on: date(day: 1))

        XCTAssertEqual(summary.remainingCOP, .zero)
        XCTAssertEqual(summary.dailyAllowanceCNY, .zero)
        XCTAssertFalse(summary.isOverBudget)
    }

    func testNegativeRemainingFundsHasZeroAllowanceAndOverBudgetFlag() throws {
        let period = makePeriod(startDay: 1, endDay: 1)
        period.confirmedIncomes = [ConfirmedIncome(amountCOP: Decimal(100), receivedAt: date(day: 1))]
        period.expenses = [
            try CNYExpense(
                amountCNY: Decimal(1),
                exchangeRateCOPPerCNY: Decimal(200),
                timestamp: date(day: 1),
                category: "Food"
            ),
        ]

        let summary = try calculate(period: period, on: date(day: 1))

        XCTAssertEqual(summary.remainingCOP, Decimal(-100))
        XCTAssertEqual(summary.dailyAllowanceCNY, .zero)
        XCTAssertTrue(summary.isOverBudget)
    }

    func testRejectsInvalidPlanningExchangeRates() {
        let period = makePeriod(startDay: 1, endDay: 10)

        for rate in [Decimal.zero, Decimal(-1), Decimal.nan] {
            XCTAssertThrowsError(
                try BudgetEngine.calculate(
                    period: period,
                    planningCOPPerCNY: rate,
                    on: date(day: 1),
                    calendar: calendar
                )
            ) { error in
                XCTAssertEqual(error as? BudgetEngineError, .invalidPlanningExchangeRate)
            }
        }
    }

    func testRejectsInvalidPeriod() {
        let period = makePeriod(startDay: 10, endDay: 1)

        XCTAssertThrowsError(
            try BudgetEngine.calculate(
                period: period,
                planningCOPPerCNY: Decimal(5_000),
                on: date(day: 1),
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(error as? BudgetEngineError, .invalidPeriod)
        }
    }

    func testExpenseCalculatesSnapshotAndRejectsInvalidEntryRates() throws {
        let expense = try CNYExpense(
            amountCNY: Decimal(string: "12.50")!,
            exchangeRateCOPPerCNY: Decimal(4_000),
            timestamp: date(day: 1),
            category: "Food",
            note: "Lunch"
        )
        XCTAssertEqual(expense.amountCOPSnapshot, Decimal(50_000))

        for rate in [Decimal.zero, Decimal(-1), Decimal.nan] {
            XCTAssertThrowsError(
                try CNYExpense(
                    amountCNY: Decimal(1),
                    exchangeRateCOPPerCNY: rate,
                    timestamp: date(day: 1),
                    category: "Food"
                )
            ) { error in
                XCTAssertEqual(error as? ExpenseValidationError, .invalidExchangeRate)
            }
        }
    }

    private func calculate(period: BudgetPeriod, on date: Date) throws -> BudgetSummary {
        try BudgetEngine.calculate(
            period: period,
            planningCOPPerCNY: Decimal(5_000),
            on: date,
            calendar: calendar
        )
    }

    private func makePeriod(startDay: Int, endDay: Int) -> BudgetPeriod {
        BudgetPeriod(startDate: date(day: startDay), endDate: date(day: endDay))
    }

    private func date(month: Int = 1, day: Int, year: Int = 2026, hour: Int = 12) -> Date {
        calendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour)
        )!
    }
}
