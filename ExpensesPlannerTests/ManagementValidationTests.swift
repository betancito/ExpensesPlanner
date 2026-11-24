import Foundation
import XCTest
@testable import ExpensesPlanner

final class ManagementValidationTests: XCTestCase {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testParsesLocalizedDecimalAndGroupingSeparatorsWithoutFloatingPointMath() {
        XCTAssertEqual(
            MoneyInput.decimal(from: " 1.250.000,75 ", locale: Locale(identifier: "es_CO")),
            Decimal(string: "1250000.75")
        )
        XCTAssertEqual(
            MoneyInput.decimal(from: "1,250,000.75", locale: Locale(identifier: "en_US")),
            Decimal(string: "1250000.75")
        )
        XCTAssertEqual(
            MoneyInput.decimal(from: "0,01", locale: Locale(identifier: "es_CO")),
            Decimal(string: "0.01")
        )
    }

    func testRejectsEmptyMalformedAndNonfiniteDecimalInput() {
        for input in ["", "   ", "abc", "1.2.3.4,xx", "NaN", "Infinity", "-Infinity"] {
            XCTAssertNil(MoneyInput.decimal(from: input), "Expected \(input) to be rejected")
        }
    }

    func testPositiveAndNonnegativeValidationUseDecimal() throws {
        XCTAssertEqual(try MoneyInput.positiveAmount(from: "0,01"), Decimal(string: "0.01"))
        XCTAssertEqual(try MoneyInput.nonnegativeAmount(from: "0"), .zero)

        for input in ["0", "-0,01", "not-money"] {
            XCTAssertThrowsError(try MoneyInput.positiveAmount(from: input)) { error in
                XCTAssertEqual(error as? ManagementValidationError, .invalidPositiveAmount)
            }
        }
        for input in ["-0,01", "not-money"] {
            XCTAssertThrowsError(try MoneyInput.nonnegativeAmount(from: input)) { error in
                XCTAssertEqual(error as? ManagementValidationError, .invalidNonnegativeAmount)
            }
        }
    }

    func testNameValidationTrimsWhitespaceAndRejectsEmptyNames() throws {
        XCTAssertEqual(try ManagementValidation.name(from: "  Arriendo  "), "Arriendo")
        for input in ["", "   ", "\n\t"] {
            XCTAssertThrowsError(try ManagementValidation.name(from: input)) { error in
                XCTAssertEqual(error as? ManagementValidationError, .emptyName)
            }
        }
    }

    func testPeriodAllowsSameCalendarDayAndRejectsEndBeforeStart() throws {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 2, day: 10, hour: 12))!
        let sameDayLater = utcCalendar.date(from: DateComponents(year: 2026, month: 2, day: 10, hour: 18))!
        let previousDay = utcCalendar.date(from: DateComponents(year: 2026, month: 2, day: 9, hour: 23))!

        try ManagementValidation.dateRange(start: start, end: sameDayLater, calendar: utcCalendar)
        XCTAssertThrowsError(try ManagementValidation.dateRange(start: start, end: previousDay, calendar: utcCalendar)) { error in
            XCTAssertEqual(error as? ManagementValidationError, .invalidPeriod)
        }
    }

    func testPeriodTotalsIncludeAllConfirmedIncomeAndObligations() {
        let period = BudgetPeriod(startDate: .distantPast, endDate: .distantFuture)
        period.confirmedIncomes = [
            ConfirmedIncome(amountCOP: Decimal(string: "1000000.25")!, receivedAt: .now),
            ConfirmedIncome(amountCOP: Decimal(string: "500000.50")!, receivedAt: .now),
        ]
        period.obligations = [
            PeriodObligation(name: "Rent", amountCOP: Decimal(string: "300000.10")!),
            PeriodObligation(name: "Utilities", amountCOP: Decimal(string: "100000.20")!),
        ]

        let totals = PeriodTotals(period: period)

        XCTAssertEqual(totals.confirmedIncomeCOP, Decimal(string: "1500000.75"))
        XCTAssertEqual(totals.obligationsCOP, Decimal(string: "400000.30"))
        XCTAssertEqual(totals.remainingBeforeSavingsAndExpensesCOP, Decimal(string: "1100000.45"))
    }

    func testSavingsProgressIsClampedAndHandlesEmptyTarget() {
        XCTAssertEqual(SavingsGoalMath.progress(savedCOP: 250, targetCOP: 1_000), Decimal(string: "0.25"))
        XCTAssertEqual(SavingsGoalMath.progress(savedCOP: 1_500, targetCOP: 1_000), 1)
        XCTAssertEqual(SavingsGoalMath.progress(savedCOP: -1, targetCOP: 1_000), 0)
        XCTAssertEqual(SavingsGoalMath.progress(savedCOP: 100, targetCOP: 0), 0)
    }

    func testCOPFormattingUsesSpanishGroupingAndExplicitCurrency() {
        let formatted = COPFormatter.string(Decimal(string: "1500000.50")!)
        XCTAssertTrue(formatted.contains("COP"))
        XCTAssertTrue(formatted.contains("1.500.000,50"), formatted)
    }
}
