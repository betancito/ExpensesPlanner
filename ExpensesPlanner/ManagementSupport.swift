import Foundation

enum ManagementValidationError: Error, Equatable, LocalizedError {
    case emptyName
    case invalidPositiveAmount
    case invalidNonnegativeAmount
    case invalidPeriod

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Escribe un nombre; no puede quedar vacío."
        case .invalidPositiveAmount:
            return "Ingresa un monto válido mayor que cero."
        case .invalidNonnegativeAmount:
            return "Ingresa un monto válido igual o mayor que cero."
        case .invalidPeriod:
            return "La fecha de finalización no puede ser anterior a la fecha de inicio."
        }
    }
}

enum MoneyInput {
    static let appLocale = Locale(identifier: "es_CO")

    static func decimal(from input: String, locale: Locale = appLocale) -> Decimal? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.isLenient = false
        formatter.usesGroupingSeparator = true

        guard let number = formatter.number(from: trimmed),
              number != NSDecimalNumber.notANumber else {
            return nil
        }
        let value = number.decimalValue
        return value.isFinite ? value : nil
    }

    static func positiveAmount(from input: String, locale: Locale = appLocale) throws -> Decimal {
        guard let amount = decimal(from: input, locale: locale), amount > .zero else {
            throw ManagementValidationError.invalidPositiveAmount
        }
        return amount
    }

    static func nonnegativeAmount(from input: String, locale: Locale = appLocale) throws -> Decimal {
        guard let amount = decimal(from: input, locale: locale), amount >= .zero else {
            throw ManagementValidationError.invalidNonnegativeAmount
        }
        return amount
    }
}

enum ManagementValidation {
    static func name(from input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ManagementValidationError.emptyName }
        return trimmed
    }

    static func dateRange(start: Date, end: Date, calendar: Calendar = .current) throws {
        guard calendar.startOfDay(for: start) <= calendar.startOfDay(for: end) else {
            throw ManagementValidationError.invalidPeriod
        }
    }
}

struct PeriodTotals: Equatable {
    let confirmedIncomeCOP: Decimal
    let obligationsCOP: Decimal
    let remainingBeforeSavingsAndExpensesCOP: Decimal

    init(period: BudgetPeriod) {
        confirmedIncomeCOP = period.confirmedIncomes.reduce(Decimal.zero) { $0 + $1.amountCOP }
        obligationsCOP = period.obligations.reduce(Decimal.zero) { $0 + $1.amountCOP }
        remainingBeforeSavingsAndExpensesCOP = confirmedIncomeCOP - obligationsCOP
    }
}

enum SavingsGoalMath {
    static func progress(savedCOP: Decimal, targetCOP: Decimal) -> Decimal {
        guard targetCOP > .zero else { return .zero }
        return min(max(savedCOP / targetCOP, .zero), Decimal(1))
    }
}

enum COPFormatter {
    static func string(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = MoneyInput.appLocale
        formatter.numberStyle = .currency
        formatter.currencyCode = "COP"
        formatter.currencySymbol = "COP "
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "COP 0,00"
    }
}

enum ManagementDateFormatter {
    static func string(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = MoneyInput.appLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func range(start: Date, end: Date) -> String {
        "\(string(start)) – \(string(end))"
    }
}

extension Decimal {
    var managementInputString: String {
        let formatter = NumberFormatter()
        formatter.locale = MoneyInput.appLocale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "0"
    }
}
