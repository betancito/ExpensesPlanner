import Foundation
import XCTest
@testable import ExpensesPlanner

final class AssetAccountTests: XCTestCase {
    func testValidationTrimsNameAndPreservesLocalizedDecimalTypeAndCurrency() throws {
        let values = try AssetAccountInput(
            name: "  Cuenta nómina  ",
            type: .checking,
            currency: .cop,
            balance: " 1.250.000,75 "
        ).validated(locale: Locale(identifier: "es_CO"))

        XCTAssertEqual(values.name, "Cuenta nómina")
        XCTAssertEqual(values.type, .checking)
        XCTAssertEqual(values.currency, .cop)
        XCTAssertEqual(values.balance, Decimal(string: "1250000.75"))
    }

    func testValidationAcceptsZeroAndRejectsBlankNamesNegativeAndMalformedBalances() throws {
        let zero = try AssetAccountInput(
            name: "Cuenta vacía",
            type: .savings,
            currency: .cny,
            balance: "0,00"
        ).validated()
        XCTAssertEqual(zero.balance, .zero)

        for input in ["", "   ", "\n\t"] {
            XCTAssertThrowsError(try AssetAccountInput(
                name: input,
                type: .checking,
                currency: .cop,
                balance: "100"
            ).validated()) { error in
                XCTAssertEqual(error as? ManagementValidationError, .emptyName)
            }
        }

        for input in ["-0,01", "not-money", "", "NaN", "Infinity"] {
            XCTAssertThrowsError(try AssetAccountInput(
                name: "Cuenta",
                type: .checking,
                currency: .cop,
                balance: input
            ).validated()) { error in
                XCTAssertEqual(error as? ManagementValidationError, .invalidNonnegativeAmount)
            }
        }
    }

    func testTotalsSeparateAccountTypesAndCurrenciesWithoutConversion() {
        let accounts = [
            AssetAccount(name: "Daily COP", type: .checking, currency: .cop, balance: Decimal(string: "1000000.10")!),
            AssetAccount(name: "Other COP", type: .checking, currency: .cop, balance: Decimal(string: "500000.20")!),
            AssetAccount(name: "Savings COP", type: .savings, currency: .cop, balance: Decimal(string: "250000.30")!),
            AssetAccount(name: "Daily CNY", type: .checking, currency: .cny, balance: Decimal(string: "125.40")!),
            AssetAccount(name: "Savings CNY", type: .savings, currency: .cny, balance: Decimal(string: "50.50")!),
        ]

        let totals = AssetAccountTotals(accounts: accounts)

        XCTAssertEqual(totals.subtotal(type: .checking, currency: .cop), Decimal(string: "1500000.30"))
        XCTAssertEqual(totals.subtotal(type: .savings, currency: .cop), Decimal(string: "250000.30"))
        XCTAssertEqual(totals.total(currency: .cop), Decimal(string: "1750000.60"))
        XCTAssertEqual(totals.subtotal(type: .checking, currency: .cny), Decimal(string: "125.40"))
        XCTAssertEqual(totals.subtotal(type: .savings, currency: .cny), Decimal(string: "50.50"))
        XCTAssertEqual(totals.total(currency: .cny), Decimal(string: "175.90"))
    }

    func testSpanishTypeLabelsExplainDailyUseAndAccumulatedSavings() {
        XCTAssertEqual(AssetAccountType.checking.displayName, "Corriente")
        XCTAssertEqual(AssetAccountType.savings.displayName, "Ahorros")
        XCTAssertTrue(AssetAccountType.checking.explanation.contains("uso diario"))
        XCTAssertTrue(AssetAccountType.savings.explanation.contains("ahorro"))
        XCTAssertEqual(AssetCurrency.allCases.map(\.rawValue), ["COP", "CNY"])
    }

    func testAssetFormattingKeepsCurrencyCodeAndSpanishDecimals() {
        let cop = AssetCurrencyFormatter.string(Decimal(string: "1250000.75")!, currency: .cop)
        let cny = AssetCurrencyFormatter.string(Decimal(string: "1250.50")!, currency: .cny)

        XCTAssertTrue(cop.contains("COP"), cop)
        XCTAssertTrue(cop.contains("1.250.000,75"), cop)
        XCTAssertTrue(cny.contains("CNY"), cny)
        XCTAssertTrue(cny.contains("1.250,50"), cny)
    }
}
