import SwiftData
import SwiftUI

struct PeriodsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetPeriod.startDate, order: .reverse) private var periods: [BudgetPeriod]
    @State private var isAddingPeriod = false
    @State private var periodToEdit: BudgetPeriod?
    @State private var periodToDelete: BudgetPeriod?
    @State private var deletionError: String?

    var body: some View {
        List {
            if periods.isEmpty {
                ContentUnavailableView(
                    "Aún no hay períodos",
                    systemImage: "calendar.badge.plus",
                    description: Text("Crea un período flexible para registrar ingresos confirmados y obligaciones.")
                )
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("periodsEmptyState")
            } else {
                Section {
                    ForEach(periods) { period in
                        NavigationLink(destination: PeriodDetailView(period: period)) {
                            PeriodRow(period: period)
                        }
                        .accessibilityIdentifier("periodRow-\(period.id.uuidString)")
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Eliminar", role: .destructive) {
                                periodToDelete = period
                            }
                            .accessibilityIdentifier("deletePeriod-\(period.id.uuidString)")
                            Button("Editar") {
                                periodToEdit = period
                            }
                            .tint(.indigo)
                            .accessibilityIdentifier("editPeriod-\(period.id.uuidString)")
                        }
                    }
                } header: {
                    Text("Períodos de presupuesto")
                } footer: {
                    Text("El saldo flexible aquí no descuenta metas de ahorro ni gastos.")
                }
            }
        }
        .navigationTitle(ContentView.title)
        .accessibilityIdentifier("managementTitle")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingPeriod = true
                } label: {
                    Label("Nuevo período", systemImage: "plus")
                }
                .accessibilityIdentifier("addPeriodButton")
            }
        }
        .sheet(isPresented: $isAddingPeriod) {
            PeriodFormView()
        }
        .sheet(item: $periodToEdit) { period in
            PeriodFormView(period: period)
        }
        .alert(
            "¿Eliminar período?",
            isPresented: Binding(
                get: { periodToDelete != nil },
                set: { if !$0 { periodToDelete = nil } }
            ),
            presenting: periodToDelete
        ) { period in
            Button("Cancelar", role: .cancel) { periodToDelete = nil }
            Button("Eliminar período", role: .destructive) {
                delete(period)
            }
        } message: { _ in
            Text("También se eliminarán sus ingresos, obligaciones y gastos asociados. Esta acción no se puede deshacer.")
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

    private func delete(_ period: BudgetPeriod) {
        modelContext.delete(period)
        do {
            try modelContext.save()
            periodToDelete = nil
        } catch {
            modelContext.rollback()
            deletionError = error.localizedDescription
        }
    }
}

private struct PeriodRow: View {
    let period: BudgetPeriod

    private var totals: PeriodTotals { PeriodTotals(period: period) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ManagementDateFormatter.range(start: period.startDate, end: period.endDate))
                .font(.headline)
                .accessibilityIdentifier("periodRange-\(period.id.uuidString)")

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ingresos confirmados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(COPFormatter.string(totals.confirmedIncomeCOP))
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Saldo flexible")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(COPFormatter.string(totals.remainingBeforeSavingsAndExpensesCOP))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(totals.remainingBeforeSavingsAndExpensesCOP < .zero ? .red : .primary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct PeriodFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingPeriod: BudgetPeriod?
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var errorMessage: String?

    init(period: BudgetPeriod? = nil) {
        existingPeriod = period
        let today = Calendar.current.startOfDay(for: .now)
        _startDate = State(initialValue: period?.startDate ?? today)
        _endDate = State(initialValue: period?.endDate ?? today)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Fecha de inicio", selection: $startDate, displayedComponents: .date)
                        .accessibilityIdentifier("periodStartDate")
                    DatePicker("Fecha de finalización", selection: $endDate, displayedComponents: .date)
                        .accessibilityIdentifier("periodEndDate")
                } header: {
                    Text("Cobertura flexible")
                } footer: {
                    Text("Elige cualquier rango; no depende de una quincena o nómina predefinida.")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("periodFormError")
                }
            }
            .navigationTitle(existingPeriod == nil ? "Nuevo período" : "Editar período")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .accessibilityIdentifier("savePeriodButton")
                }
            }
        }
    }

    private func save() {
        do {
            try ManagementValidation.dateRange(start: startDate, end: endDate)
            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.startOfDay(for: endDate)
            if let existingPeriod {
                existingPeriod.startDate = start
                existingPeriod.endDate = end
            } else {
                modelContext.insert(BudgetPeriod(startDate: start, endDate: end))
            }
            try modelContext.save()
            dismiss()
        } catch let error as ManagementValidationError {
            errorMessage = error.errorDescription
        } catch {
            modelContext.rollback()
            errorMessage = "No se pudo guardar el período. Inténtalo de nuevo."
        }
    }
}

struct PeriodDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var period: BudgetPeriod

    @State private var isAddingIncome = false
    @State private var incomeToEdit: ConfirmedIncome?
    @State private var incomeToDelete: ConfirmedIncome?
    @State private var isAddingObligation = false
    @State private var obligationToEdit: PeriodObligation?
    @State private var obligationToDelete: PeriodObligation?
    @State private var actionError: String?

    private var totals: PeriodTotals { PeriodTotals(period: period) }

    var body: some View {
        List {
            Section("Resumen del período") {
                LabeledContent("Fechas") {
                    Text(ManagementDateFormatter.range(start: period.startDate, end: period.endDate))
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Ingresos confirmados") {
                    Text(COPFormatter.string(totals.confirmedIncomeCOP))
                        .accessibilityIdentifier("confirmedIncomeTotal")
                }
                LabeledContent("Obligaciones") {
                    Text(COPFormatter.string(totals.obligationsCOP))
                        .accessibilityIdentifier("obligationsTotal")
                }
                LabeledContent("Saldo flexible") {
                    Text(COPFormatter.string(totals.remainingBeforeSavingsAndExpensesCOP))
                        .fontWeight(.semibold)
                        .foregroundStyle(totals.remainingBeforeSavingsAndExpensesCOP < .zero ? .red : .primary)
                        .accessibilityIdentifier("remainingFlexibleTotal")
                }
                Text("Ingresos menos obligaciones, antes de ahorros y gastos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                if period.confirmedIncomes.isEmpty {
                    Text("No hay ingresos confirmados. Agrega únicamente dinero que ya recibiste.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("incomesEmptyState")
                } else {
                    ForEach(sortedIncomes) { income in
                        Button {
                            incomeToEdit = income
                        } label: {
                            LabeledContent {
                                Text(COPFormatter.string(income.amountCOP))
                                    .foregroundStyle(.primary)
                            } label: {
                                Label(ManagementDateFormatter.string(income.receivedAt), systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .accessibilityIdentifier("incomeRow-\(income.id.uuidString)")
                        .swipeActions(edge: .trailing) {
                            Button("Eliminar", role: .destructive) { incomeToDelete = income }
                                .accessibilityIdentifier("deleteIncome-\(income.id.uuidString)")
                        }
                    }
                }
                Button {
                    isAddingIncome = true
                } label: {
                    Label("Agregar ingreso confirmado", systemImage: "plus.circle")
                }
                .accessibilityIdentifier("addIncomeButton")
            } header: {
                Text("Ingresos confirmados en COP")
            }

            Section {
                if period.obligations.isEmpty {
                    Text("No hay obligaciones en este período.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("obligationsEmptyState")
                } else {
                    ForEach(sortedObligations) { obligation in
                        Button {
                            obligationToEdit = obligation
                        } label: {
                            LabeledContent {
                                Text(COPFormatter.string(obligation.amountCOP))
                                    .foregroundStyle(.primary)
                            } label: {
                                Text(obligation.name)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .accessibilityIdentifier("obligationRow-\(obligation.id.uuidString)")
                        .swipeActions(edge: .trailing) {
                            Button("Eliminar", role: .destructive) { obligationToDelete = obligation }
                                .accessibilityIdentifier("deleteObligation-\(obligation.id.uuidString)")
                        }
                    }
                }
                Button {
                    isAddingObligation = true
                } label: {
                    Label("Agregar obligación", systemImage: "plus.circle")
                }
                .accessibilityIdentifier("addObligationButton")
            } header: {
                Text("Obligaciones variables")
            }
        }
        .navigationTitle("Detalle del período")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingIncome) {
            IncomeFormView(period: period)
        }
        .sheet(item: $incomeToEdit) { income in
            IncomeFormView(period: period, income: income)
        }
        .sheet(isPresented: $isAddingObligation) {
            ObligationFormView(period: period)
        }
        .sheet(item: $obligationToEdit) { obligation in
            ObligationFormView(period: period, obligation: obligation)
        }
        .alert(
            "¿Eliminar ingreso?",
            isPresented: Binding(get: { incomeToDelete != nil }, set: { if !$0 { incomeToDelete = nil } }),
            presenting: incomeToDelete
        ) { income in
            Button("Cancelar", role: .cancel) { incomeToDelete = nil }
            Button("Eliminar ingreso", role: .destructive) { deleteIncome(income) }
        } message: { _ in
            Text("El total de ingresos confirmados se actualizará.")
        }
        .alert(
            "¿Eliminar obligación?",
            isPresented: Binding(get: { obligationToDelete != nil }, set: { if !$0 { obligationToDelete = nil } }),
            presenting: obligationToDelete
        ) { obligation in
            Button("Cancelar", role: .cancel) { obligationToDelete = nil }
            Button("Eliminar obligación", role: .destructive) { deleteObligation(obligation) }
        } message: { _ in
            Text("El saldo flexible del período se actualizará.")
        }
        .alert("No se pudo completar la acción", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } }
        )) {
            Button("Aceptar") { actionError = nil }
        } message: {
            Text(actionError ?? "Inténtalo de nuevo.")
        }
    }

    private var sortedIncomes: [ConfirmedIncome] {
        period.confirmedIncomes.sorted { $0.receivedAt > $1.receivedAt }
    }

    private var sortedObligations: [PeriodObligation] {
        period.obligations.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func deleteIncome(_ income: ConfirmedIncome) {
        modelContext.delete(income)
        saveDeletion()
    }

    private func deleteObligation(_ obligation: PeriodObligation) {
        modelContext.delete(obligation)
        saveDeletion()
    }

    private func saveDeletion() {
        do {
            try modelContext.save()
            incomeToDelete = nil
            obligationToDelete = nil
        } catch {
            modelContext.rollback()
            actionError = error.localizedDescription
        }
    }
}

struct IncomeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let period: BudgetPeriod
    private let existingIncome: ConfirmedIncome?
    @State private var amount: String
    @State private var receivedAt: Date
    @State private var errorMessage: String?

    init(period: BudgetPeriod, income: ConfirmedIncome? = nil) {
        self.period = period
        existingIncome = income
        _amount = State(initialValue: income?.amountCOP.managementInputString ?? "")
        _receivedAt = State(initialValue: income?.receivedAt ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Monto en COP", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("incomeAmountField")
                    DatePicker("Fecha de recibo", selection: $receivedAt, displayedComponents: .date)
                        .accessibilityIdentifier("incomeReceivedDate")
                } header: {
                    Text("Dinero ya recibido")
                } footer: {
                    Text("Usa formato decimal, por ejemplo 1.250.000,50. Solo los ingresos confirmados aumentan el saldo.")
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("incomeFormError")
                }
            }
            .navigationTitle(existingIncome == nil ? "Nuevo ingreso" : "Editar ingreso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .accessibilityIdentifier("saveIncomeButton")
                }
            }
        }
    }

    private func save() {
        do {
            let validAmount = try MoneyInput.positiveAmount(from: amount)
            if let existingIncome {
                existingIncome.amountCOP = validAmount
                existingIncome.receivedAt = receivedAt
            } else {
                modelContext.insert(ConfirmedIncome(amountCOP: validAmount, receivedAt: receivedAt, period: period))
            }
            try modelContext.save()
            dismiss()
        } catch let error as ManagementValidationError {
            errorMessage = error.errorDescription
        } catch {
            modelContext.rollback()
            errorMessage = "No se pudo guardar el ingreso. Inténtalo de nuevo."
        }
    }
}

struct ObligationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let period: BudgetPeriod
    private let existingObligation: PeriodObligation?
    @State private var name: String
    @State private var amount: String
    @State private var errorMessage: String?

    init(period: BudgetPeriod, obligation: PeriodObligation? = nil) {
        self.period = period
        existingObligation = obligation
        _name = State(initialValue: obligation?.name ?? "")
        _amount = State(initialValue: obligation?.amountCOP.managementInputString ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $name)
                        .accessibilityIdentifier("obligationNameField")
                    TextField("Monto en COP", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("obligationAmountField")
                } header: {
                    Text("Obligación del período")
                } footer: {
                    Text("Puedes cambiar el nombre y el monto en cada período.")
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("obligationFormError")
                }
            }
            .navigationTitle(existingObligation == nil ? "Nueva obligación" : "Editar obligación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .accessibilityIdentifier("saveObligationButton")
                }
            }
        }
    }

    private func save() {
        do {
            let validName = try ManagementValidation.name(from: name)
            let validAmount = try MoneyInput.positiveAmount(from: amount)
            if let existingObligation {
                existingObligation.name = validName
                existingObligation.amountCOP = validAmount
            } else {
                modelContext.insert(PeriodObligation(name: validName, amountCOP: validAmount, period: period))
            }
            try modelContext.save()
            dismiss()
        } catch let error as ManagementValidationError {
            errorMessage = error.errorDescription
        } catch {
            modelContext.rollback()
            errorMessage = "No se pudo guardar la obligación. Inténtalo de nuevo."
        }
    }
}
