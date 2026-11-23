import Foundation
import SwiftData
import XCTest
@testable import ExpensesPlanner

@MainActor
final class FinancePersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try FinanceModelContainer.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testBudgetPeriodRoundTrip() throws {
        let id = UUID()
        let startDate = Date(timeIntervalSince1970: 1_767_225_600)
        let endDate = Date(timeIntervalSince1970: 1_768_003_200)
        let period = BudgetPeriod(id: id, startDate: startDate, endDate: endDate)
        context.insert(period)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<BudgetPeriod>()).first)
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.startDate, startDate)
        XCTAssertEqual(fetched.endDate, endDate)
        XCTAssertTrue(fetched.confirmedIncomes.isEmpty)
        XCTAssertTrue(fetched.obligations.isEmpty)
        XCTAssertTrue(fetched.expenses.isEmpty)
    }

    func testConfirmedIncomeRoundTripAndPeriodRelationship() throws {
        let period = BudgetPeriod(
            startDate: Date(timeIntervalSince1970: 1_767_225_600),
            endDate: Date(timeIntervalSince1970: 1_768_003_200)
        )
        let id = UUID()
        let receivedAt = Date(timeIntervalSince1970: 1_767_312_000)
        let income = ConfirmedIncome(
            id: id,
            amountCOP: Decimal(string: "1250000.75")!,
            receivedAt: receivedAt,
            period: period
        )
        context.insert(period)
        context.insert(income)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<ConfirmedIncome>()).first)
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.amountCOP, Decimal(string: "1250000.75")!)
        XCTAssertEqual(fetched.receivedAt, receivedAt)
        XCTAssertEqual(fetched.period?.id, period.id)
        XCTAssertEqual(fetched.period?.confirmedIncomes.map(\.id), [id])
    }

    func testPeriodObligationRoundTripAndPeriodRelationship() throws {
        let period = BudgetPeriod(
            startDate: Date(timeIntervalSince1970: 1_767_225_600),
            endDate: Date(timeIntervalSince1970: 1_768_003_200)
        )
        let id = UUID()
        let obligation = PeriodObligation(
            id: id,
            name: "Rent and utilities",
            amountCOP: Decimal(string: "800000.50")!,
            period: period
        )
        context.insert(period)
        context.insert(obligation)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<PeriodObligation>()).first)
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.name, "Rent and utilities")
        XCTAssertEqual(fetched.amountCOP, Decimal(string: "800000.50")!)
        XCTAssertEqual(fetched.period?.id, period.id)
        XCTAssertEqual(fetched.period?.obligations.map(\.id), [id])
    }

    func testSavingsGoalsRoundTripWithAndWithoutTargetDate() throws {
        let targetDate = Date(timeIntervalSince1970: 1_798_156_800)
        let datedGoal = SavingsGoal(
            name: "Travel",
            targetCOP: Decimal(string: "5000000.25")!,
            targetDate: targetDate,
            savedCOP: Decimal(string: "1250000.50")!,
            plannedAllocationCOP: Decimal(string: "250000.75")!
        )
        let undatedGoal = SavingsGoal(
            name: "Emergency fund",
            targetCOP: Decimal(10_000_000),
            savedCOP: Decimal(2_000_000),
            plannedAllocationCOP: Decimal(500_000)
        )
        context.insert(datedGoal)
        context.insert(undatedGoal)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavingsGoal>())
        XCTAssertEqual(fetched.count, 2)
        let fetchedDatedGoal = try XCTUnwrap(fetched.first { $0.id == datedGoal.id })
        XCTAssertEqual(fetchedDatedGoal.name, "Travel")
        XCTAssertEqual(fetchedDatedGoal.targetCOP, Decimal(string: "5000000.25")!)
        XCTAssertEqual(fetchedDatedGoal.targetDate, targetDate)
        XCTAssertEqual(fetchedDatedGoal.savedCOP, Decimal(string: "1250000.50")!)
        XCTAssertEqual(fetchedDatedGoal.plannedAllocationCOP, Decimal(string: "250000.75")!)
        let fetchedUndatedGoal = try XCTUnwrap(fetched.first { $0.id == undatedGoal.id })
        XCTAssertNil(fetchedUndatedGoal.targetDate)
        XCTAssertEqual(fetchedUndatedGoal.savedCOP, Decimal(2_000_000))
        XCTAssertEqual(fetchedUndatedGoal.plannedAllocationCOP, Decimal(500_000))
    }

    func testCNYExpenseRoundTripPreservesSnapshotMetadataAndPeriodRelationship() throws {
        let period = BudgetPeriod(
            startDate: Date(timeIntervalSince1970: 1_767_225_600),
            endDate: Date(timeIntervalSince1970: 1_768_003_200)
        )
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1_767_398_400)
        let expense = try CNYExpense(
            id: id,
            amountCNY: Decimal(string: "12.50")!,
            exchangeRateCOPPerCNY: Decimal(string: "4000.25")!,
            timestamp: timestamp,
            category: "Food",
            note: "Lunch",
            period: period
        )
        context.insert(period)
        context.insert(expense)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<CNYExpense>()).first)
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.amountCNY, Decimal(string: "12.50")!)
        XCTAssertEqual(fetched.exchangeRateCOPPerCNY, Decimal(string: "4000.25")!)
        XCTAssertEqual(fetched.amountCOPSnapshot, Decimal(string: "50003.125")!)
        XCTAssertEqual(fetched.timestamp, timestamp)
        XCTAssertEqual(fetched.category, "Food")
        XCTAssertEqual(fetched.note, "Lunch")
        XCTAssertEqual(fetched.period?.id, period.id)
        XCTAssertEqual(fetched.period?.expenses.map(\.id), [id])
    }

    func testExchangeRateSnapshotRoundTripPreservesRateTimestampAndOriginMetadata() throws {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1_767_398_400)
        let snapshot = try ExchangeRateSnapshot(
            id: id,
            rateCOPPerCNY: Decimal(string: "4012.345678")!,
            timestamp: timestamp,
            provider: "https://www.exchangerate-api.com",
            source: "https://open.er-api.com/v6/latest/CNY",
            origin: .network
        )
        context.insert(snapshot)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<ExchangeRateSnapshot>()).first)
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.rateCOPPerCNY, Decimal(string: "4012.345678")!)
        XCTAssertEqual(fetched.timestamp, timestamp)
        XCTAssertEqual(fetched.provider, "https://www.exchangerate-api.com")
        XCTAssertEqual(fetched.source, "https://open.er-api.com/v6/latest/CNY")
        XCTAssertEqual(fetched.origin, .network)
    }
}
