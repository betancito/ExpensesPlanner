import SwiftData
import SwiftUI

struct SavingsGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.name) private var goals: [SavingsGoal]
    @State private var presentedGoalForm: GoalFormPresentation?
    @State private var goalToDelete: SavingsGoal?
    @State private var deletionError: String?

    var body: some View {
        List {
            if goals.isEmpty {
                ContentUnavailableView(
                    "Aún no hay metas",
                    systemImage: "target",
                    description: Text("Define un objetivo en COP y una asignación planeada para cada período.")
                )
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("goalsEmptyState")
            } else {
                Section {
                    ForEach(goals) { goal in
                        SavingsGoalRow(goal: goal) {
                            presentedGoalForm = .edit(goal)
                        }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Eliminar", role: .destructive) { goalToDelete = goal }
                                    .accessibilityIdentifier("deleteGoal-\(goal.id.uuidString)")
                            }
                    }
                } footer: {
                    Text("Las asignaciones son valores planeados; no crean transferencias automáticas.")
                }
            }
        }
        .navigationTitle("Metas de ahorro")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedGoalForm = .create
                } label: {
                    Label("Nueva meta", systemImage: "plus")
                }
                .accessibilityIdentifier("addGoalButton")
            }
        }
        .sheet(item: $presentedGoalForm) { presentation in
            SavingsGoalFormView(goal: presentation.goal)
        }
        .alert(
            "¿Eliminar meta?",
            isPresented: Binding(get: { goalToDelete != nil }, set: { if !$0 { goalToDelete = nil } }),
            presenting: goalToDelete
        ) { goal in
            Button("Cancelar", role: .cancel) { goalToDelete = nil }
            Button("Eliminar meta", role: .destructive) { delete(goal) }
        } message: { _ in
            Text("Se eliminarán el objetivo y su asignación planeada. Esta acción no se puede deshacer.")
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

    private func delete(_ goal: SavingsGoal) {
        modelContext.delete(goal)
        do {
            try modelContext.save()
            goalToDelete = nil
        } catch {
            modelContext.rollback()
            deletionError = error.localizedDescription
        }
    }
}

private enum GoalFormPresentation: Identifiable {
    case create
    case edit(SavingsGoal)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let goal):
            return goal.id.uuidString
        }
    }

    var goal: SavingsGoal? {
        switch self {
        case .create:
            return nil
        case .edit(let goal):
            return goal
        }
    }
}

private struct SavingsGoalRow: View {
    @Bindable var goal: SavingsGoal
    let onEdit: () -> Void

    private var progress: Decimal {
        SavingsGoalMath.progress(savedCOP: goal.savedCOP, targetCOP: goal.targetCOP)
    }

    var body: some View {
        Button {
            onEdit()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goal.name)
                        .font(.headline)
                    Spacer()
                    Text("\(NSDecimalNumber(decimal: progress * 100).intValue) %")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.indigo)
                }

                ProgressView(value: NSDecimalNumber(decimal: progress).doubleValue)
                    .tint(.indigo)
                    .accessibilityIdentifier("goalProgress-\(goal.id.uuidString)")

                LabeledContent("Ahorrado") {
                    Text(COPFormatter.string(goal.savedCOP))
                }
                LabeledContent("Objetivo") {
                    Text(COPFormatter.string(goal.targetCOP))
                }
                LabeledContent("Asignación por período") {
                    Text(COPFormatter.string(goal.plannedAllocationCOP))
                }
                if let targetDate = goal.targetDate {
                    LabeledContent("Fecha objetivo") {
                        Text(ManagementDateFormatter.string(targetDate))
                    }
                } else {
                    Text("Sin fecha objetivo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 6)
        }
        .accessibilityIdentifier("goalRow-\(goal.id.uuidString)")
    }
}

private enum GoalFormField: Hashable {
    case name
    case target
    case saved
    case plannedAllocation
}

struct SavingsGoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingGoal: SavingsGoal?
    @State private var name: String
    @State private var target: String
    @State private var saved: String
    @State private var plannedAllocation: String
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var errorMessage: String?
    @FocusState private var focusedField: GoalFormField?

    init(goal: SavingsGoal? = nil) {
        existingGoal = goal
        _name = State(initialValue: goal?.name ?? "")
        _target = State(initialValue: goal?.targetCOP.managementInputString ?? "")
        _saved = State(initialValue: goal?.savedCOP.managementInputString ?? "0")
        _plannedAllocation = State(initialValue: goal?.plannedAllocationCOP.managementInputString ?? "0")
        _hasTargetDate = State(initialValue: goal?.targetDate != nil)
        _targetDate = State(initialValue: goal?.targetDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Objetivo") {
                    TextField("Nombre", text: $name)
                        .focused($focusedField, equals: .name)
                        .accessibilityIdentifier("goalNameField")
                    TextField("Meta en COP", text: $target)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .target)
                        .accessibilityIdentifier("goalTargetField")
                    Toggle("Incluir fecha objetivo", isOn: $hasTargetDate)
                        .accessibilityIdentifier("goalTargetDateToggle")
                    if hasTargetDate {
                        DatePicker("Fecha objetivo", selection: $targetDate, displayedComponents: .date)
                            .accessibilityIdentifier("goalTargetDate")
                    }
                }

                Section {
                    TextField("Ahorrado en COP", text: $saved)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .saved)
                        .accessibilityIdentifier("goalSavedField")
                    TextField("Asignación por período en COP", text: $plannedAllocation)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .plannedAllocation)
                        .accessibilityIdentifier("goalAllocationField")
                } header: {
                    Text("Progreso y plan")
                } footer: {
                    Text("Los valores ahorrado y asignación pueden ser cero. La asignación no genera movimientos automáticos.")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("goalFormError")
                }
            }
            .navigationTitle(existingGoal == nil ? "Nueva meta" : "Editar meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .accessibilityIdentifier("saveGoalButton")
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Listo") { focusedField = nil }
                        .accessibilityIdentifier("dismissGoalKeyboardButton")
                }
            }
        }
    }

    private func save() {
        do {
            let validName = try ManagementValidation.name(from: name)
            let validTarget = try MoneyInput.positiveAmount(from: target)
            let validSaved = try MoneyInput.nonnegativeAmount(from: saved)
            let validAllocation = try MoneyInput.nonnegativeAmount(from: plannedAllocation)
            let validTargetDate = hasTargetDate ? targetDate : nil

            if let existingGoal {
                existingGoal.name = validName
                existingGoal.targetCOP = validTarget
                existingGoal.targetDate = validTargetDate
                existingGoal.savedCOP = validSaved
                existingGoal.plannedAllocationCOP = validAllocation
            } else {
                modelContext.insert(SavingsGoal(
                    name: validName,
                    targetCOP: validTarget,
                    targetDate: validTargetDate,
                    savedCOP: validSaved,
                    plannedAllocationCOP: validAllocation
                ))
            }
            try modelContext.save()
            dismiss()
        } catch let error as ManagementValidationError {
            errorMessage = error.errorDescription
        } catch {
            modelContext.rollback()
            errorMessage = "No se pudo guardar la meta. Inténtalo de nuevo."
        }
    }
}
