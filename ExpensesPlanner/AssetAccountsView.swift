import SwiftData
import SwiftUI

struct AssetAccountInput {
    let name: String
    let type: AssetAccountType
    let currency: AssetCurrency
    let balance: String

    func validated(locale: Locale = MoneyInput.appLocale) throws -> AssetAccountValues {
        AssetAccountValues(
            name: try ManagementValidation.name(from: name),
            type: type,
            currency: currency,
            balance: try MoneyInput.nonnegativeAmount(from: balance, locale: locale)
        )
    }
}

struct AssetAccountValues: Equatable {
    let name: String
    let type: AssetAccountType
    let currency: AssetCurrency
    let balance: Decimal
}

struct AssetAccountTotals {
    private let accounts: [AssetAccount]

    init(accounts: [AssetAccount]) {
        self.accounts = accounts
    }

    func subtotal(type: AssetAccountType, currency: AssetCurrency) -> Decimal {
        accounts
            .filter { $0.type == type && $0.currency == currency }
            .reduce(Decimal.zero) { $0 + $1.balance }
    }

    func total(currency: AssetCurrency) -> Decimal {
        accounts
            .filter { $0.currency == currency }
            .reduce(Decimal.zero) { $0 + $1.balance }
    }
}

enum AssetCurrencyFormatter {
    static func string(_ value: Decimal, currency: AssetCurrency) -> String {
        let formatter = NumberFormatter()
        formatter.locale = MoneyInput.appLocale
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = "\(currency.rawValue) "
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(currency.rawValue) 0,00"
    }
}

struct AssetAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AssetAccount.name) private var accounts: [AssetAccount]
    @State private var presentedForm: AssetAccountFormPresentation?
    @State private var accountToDelete: AssetAccount?
    @State private var deletionError: String?

    private var totals: AssetAccountTotals {
        AssetAccountTotals(accounts: accounts)
    }

    var body: some View {
        List {
            if accounts.isEmpty {
                ContentUnavailableView(
                    "Aún no hay cuentas",
                    systemImage: "building.columns",
                    description: Text("Agrega cuentas corrientes o de ahorros y actualiza sus balances manualmente en COP o CNY.")
                )
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("assetsEmptyState")

                Section("Seguimiento manual") {
                    Text("Los balances son registros independientes: no crean ingresos, gastos, progreso de metas ni sincronización bancaria.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("assetsManualTrackingNote")
                }
            } else {
                summarySection(for: .cop)
                summarySection(for: .cny)

                Section {
                    ForEach(accounts) { account in
                        Button {
                            presentedForm = .edit(account)
                        } label: {
                            AssetAccountRow(account: account)
                        }
                        .accessibilityIdentifier("assetRow-\(account.id.uuidString)")
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Eliminar", role: .destructive) {
                                accountToDelete = account
                            }
                            .accessibilityIdentifier("deleteAssetAccount-\(account.id.uuidString)")
                        }
                    }
                } header: {
                    Text("Cuentas")
                } footer: {
                    Text("Los balances se editan manualmente. No crean ingresos, gastos, progreso de metas ni sincronización bancaria.")
                }
            }
        }
        .navigationTitle(ContentView.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedForm = .create
                } label: {
                    Label("Nueva cuenta", systemImage: "plus")
                }
                .accessibilityIdentifier("addAssetAccountButton")
            }
        }
        .sheet(item: $presentedForm) { presentation in
            AssetAccountFormView(account: presentation.account)
        }
        .alert(
            "¿Eliminar cuenta?",
            isPresented: Binding(
                get: { accountToDelete != nil },
                set: { if !$0 { accountToDelete = nil } }
            ),
            presenting: accountToDelete
        ) { account in
            Button("Cancelar", role: .cancel) { accountToDelete = nil }
            Button("Eliminar cuenta", role: .destructive) { delete(account) }
        } message: { account in
            Text("Se eliminará «\(account.name)». Solo se borra este registro manual; no se crean ingresos ni gastos. Esta acción no se puede deshacer.")
        }
        .alert("No se pudo eliminar", isPresented: Binding(
            get: { deletionError != nil },
            set: { if !$0 { deletionError = nil } }
        )) {
            Button("Aceptar") { deletionError = nil }
        } message: {
            Text(deletionError ?? "Inténtalo de nuevo.")
        }
    }

    @ViewBuilder
    private func summarySection(for currency: AssetCurrency) -> some View {
        Section("Resumen en \(currency.rawValue)") {
            LabeledContent("Corriente") {
                Text(AssetCurrencyFormatter.string(totals.subtotal(type: .checking, currency: currency), currency: currency))
                    .accessibilityIdentifier("checkingSubtotal\(currency.rawValue)")
            }
            LabeledContent("Ahorros") {
                Text(AssetCurrencyFormatter.string(totals.subtotal(type: .savings, currency: currency), currency: currency))
                    .accessibilityIdentifier("savingsSubtotal\(currency.rawValue)")
            }
            LabeledContent("Total de activos") {
                Text(AssetCurrencyFormatter.string(totals.total(currency: currency), currency: currency))
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("totalAssets\(currency.rawValue)")
            }
        }
    }

    private func delete(_ account: AssetAccount) {
        modelContext.delete(account)
        do {
            try modelContext.save()
            accountToDelete = nil
        } catch {
            modelContext.rollback()
            deletionError = error.localizedDescription
        }
    }
}

private enum AssetAccountFormPresentation: Identifiable {
    case create
    case edit(AssetAccount)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let account):
            return account.id.uuidString
        }
    }

    var account: AssetAccount? {
        switch self {
        case .create:
            return nil
        case .edit(let account):
            return account
        }
    }
}

private struct AssetAccountRow: View {
    let account: AssetAccount

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.type == .checking ? "banknote" : "archivebox")
                .foregroundStyle(.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                Text("\(account.type.displayName) · \(account.currency.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(AssetCurrencyFormatter.string(account.balance, currency: account.currency))
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier("assetBalance-\(account.id.uuidString)")
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 4)
    }
}

private enum AssetAccountFormField: Hashable {
    case name
    case balance
}

struct AssetAccountFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingAccount: AssetAccount?
    @State private var name: String
    @State private var type: AssetAccountType
    @State private var currency: AssetCurrency
    @State private var balance: String
    @State private var errorMessage: String?
    @FocusState private var focusedField: AssetAccountFormField?

    init(account: AssetAccount? = nil) {
        existingAccount = account
        _name = State(initialValue: account?.name ?? "")
        _type = State(initialValue: account?.type ?? .checking)
        _currency = State(initialValue: account?.currency ?? .cop)
        _balance = State(initialValue: account?.balance.managementInputString ?? "0")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuenta") {
                    TextField("Nombre", text: $name)
                        .focused($focusedField, equals: .name)
                        .accessibilityIdentifier("assetNameField")
                    Picker("Tipo de cuenta", selection: $type) {
                        ForEach(AssetAccountType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("assetTypePicker")
                    Text(type.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("assetTypeExplanation")
                }

                Section {
                    Picker("Moneda", selection: $currency) {
                        ForEach(AssetCurrency.allCases) { currency in
                            Text(currency.rawValue).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("assetCurrencyPicker")
                    TextField("Balance actual", text: $balance)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .balance)
                        .accessibilityIdentifier("assetBalanceField")
                } header: {
                    Text("Balance en \(currency.rawValue)")
                } footer: {
                    Text("Usa formato decimal, por ejemplo 1.250.000,50. El balance puede ser cero y se actualiza manualmente.")
                }

                Section {
                    Text("Guardar un balance no crea ingresos, gastos, progreso de metas ni movimientos entre cuentas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("assetFormError")
                }
            }
            .navigationTitle(existingAccount == nil ? "Nueva cuenta" : "Editar cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .accessibilityIdentifier("saveAssetAccountButton")
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Listo") { focusedField = nil }
                        .accessibilityIdentifier("dismissAssetKeyboardButton")
                }
            }
        }
    }

    private func save() {
        do {
            let values = try AssetAccountInput(
                name: name,
                type: type,
                currency: currency,
                balance: balance
            ).validated()

            if let existingAccount {
                existingAccount.name = values.name
                existingAccount.type = values.type
                existingAccount.currency = values.currency
                existingAccount.balance = values.balance
            } else {
                modelContext.insert(AssetAccount(
                    name: values.name,
                    type: values.type,
                    currency: values.currency,
                    balance: values.balance
                ))
            }
            try modelContext.save()
            dismiss()
        } catch let error as ManagementValidationError {
            errorMessage = error.errorDescription
        } catch {
            modelContext.rollback()
            errorMessage = "No se pudo guardar la cuenta. Inténtalo de nuevo."
        }
    }
}
