import XCTest

final class ExpensesPlannerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLaunchDisplaysSpanishManagementAndUsefulEmptyStates() {
        launchResettingData()

        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.tabBars.buttons["Activos"].exists)
        XCTAssertTrue(app.tabBars.buttons["Planificación"].exists)
        XCTAssertTrue(app.navigationBars["Activos"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("assetsEmptyState").exists)
        XCTAssertTrue(element("assetsManualTrackingNote").exists)
        XCTAssertTrue(app.buttons["Nueva cuenta"].exists)

        openPeriods()
        XCTAssertTrue(element("periodsEmptyState").exists)
        XCTAssertTrue(app.buttons["Nuevo período"].exists)

        app.navigationBars.buttons["Planificación"].tap()
        element("goalsNavigationLink").tap()
        XCTAssertTrue(app.navigationBars["Metas de ahorro"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("goalsEmptyState").exists)
        XCTAssertTrue(app.buttons["Nueva meta"].exists)
    }

    func testPeriodIncomeAndObligationCRUDValidationTotalsAndRelaunch() {
        launchResettingData()
        openPeriods()

        app.buttons["addPeriodButton"].tap()
        app.buttons["savePeriodButton"].tap()
        let periodRow = element(prefix: "periodRow-")
        XCTAssertTrue(periodRow.waitForExistence(timeout: 5))
        periodRow.tap()
        XCTAssertTrue(element("incomesEmptyState").waitForExistence(timeout: 5))
        XCTAssertTrue(element("obligationsEmptyState").exists)

        // Invalid income remains in the form and is not saved.
        app.buttons["addIncomeButton"].tap()
        replaceText(in: "incomeAmountField", with: "0")
        app.buttons["saveIncomeButton"].tap()
        XCTAssertTrue(element("incomeFormError").waitForExistence(timeout: 3))
        XCTAssertTrue(element("incomeFormError").label.contains("mayor que cero"))
        app.buttons["Cancelar"].tap()

        addIncome("1000000")
        XCTAssertTrue(element("confirmedIncomeTotal").waitForExistence(timeout: 5))
        XCTAssertTrue(element("confirmedIncomeTotal").label.contains("1.000.000,00"))
        addIncome("500000")
        XCTAssertTrue(element("confirmedIncomeTotal").label.contains("1.500.000,00"))

        // Blank obligation names are rejected without creating a row.
        app.buttons["addObligationButton"].tap()
        replaceText(in: "obligationNameField", with: "   ")
        replaceText(in: "obligationAmountField", with: "300000")
        app.buttons["saveObligationButton"].tap()
        XCTAssertTrue(element("obligationFormError").waitForExistence(timeout: 3))
        XCTAssertTrue(element("obligationFormError").label.contains("nombre"))
        app.buttons["Cancelar"].tap()

        app.buttons["addObligationButton"].tap()
        replaceText(in: "obligationNameField", with: "  Arriendo  ")
        replaceText(in: "obligationAmountField", with: "300000")
        app.buttons["saveObligationButton"].tap()
        XCTAssertTrue(app.staticTexts["Arriendo"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("obligationsTotal").label.contains("300.000,00"))
        XCTAssertTrue(element("remainingFlexibleTotal").label.contains("1.200.000,00"))

        // Edit the most recent income and verify all dependent Decimal totals update.
        let incomeRow = element(prefix: "incomeRow-")
        XCTAssertTrue(incomeRow.waitForExistence(timeout: 5))
        incomeRow.tap()
        replaceText(in: "incomeAmountField", with: "600000")
        app.buttons["saveIncomeButton"].tap()
        XCTAssertTrue(element("confirmedIncomeTotal").waitForExistence(timeout: 5))
        XCTAssertTrue(element("confirmedIncomeTotal").label.contains("1.600.000,00"))
        XCTAssertTrue(element("remainingFlexibleTotal").label.contains("1.300.000,00"))

        // Terminate and relaunch without the reset argument: persisted values must remain.
        app.terminate()
        app.launchArguments = []
        app.launch()
        openPeriods()
        let persistedPeriod = element(prefix: "periodRow-")
        XCTAssertTrue(persistedPeriod.waitForExistence(timeout: 5))
        persistedPeriod.tap()
        XCTAssertTrue(element("confirmedIncomeTotal").waitForExistence(timeout: 5))
        XCTAssertTrue(element("confirmedIncomeTotal").label.contains("1.600.000,00"))
        XCTAssertTrue(element("obligationsTotal").label.contains("300.000,00"))
        XCTAssertTrue(element("remainingFlexibleTotal").label.contains("1.300.000,00"))
        XCTAssertTrue(app.staticTexts["Arriendo"].exists)

        app.navigationBars.buttons["Períodos"].tap()
        let rowToDelete = element(prefix: "periodRow-")
        rowToDelete.swipeLeft()
        app.buttons["Eliminar"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.alerts.firstMatch.staticTexts.element(boundBy: 1).label.contains("gastos asociados"))
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(element(prefix: "periodRow-").exists)

        rowToDelete.swipeLeft()
        app.buttons["Eliminar"].tap()
        app.alerts.buttons["Eliminar período"].tap()
        XCTAssertTrue(element("periodsEmptyState").waitForExistence(timeout: 5))
    }

    func testAssetAccountsCreateEditValidationTotalsDeletionAndRelaunch() {
        launchResettingData()

        XCTAssertTrue(app.navigationBars["Activos"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("assetsEmptyState").exists)

        // Blank names and missing balances are rejected without creating an account.
        app.buttons["addAssetAccountButton"].tap()
        replaceText(in: "assetNameField", with: "   ")
        app.buttons["saveAssetAccountButton"].tap()
        XCTAssertTrue(element("assetFormError").waitForExistence(timeout: 3))
        XCTAssertTrue(element("assetFormError").label.contains("nombre"))
        replaceText(in: "assetNameField", with: "Inválida")
        replaceText(in: "assetBalanceField", with: "")
        app.buttons["saveAssetAccountButton"].tap()
        XCTAssertTrue(element("assetFormError").label.contains("igual o mayor que cero"))
        app.buttons["Cancelar"].tap()
        XCTAssertTrue(element("assetsEmptyState").waitForExistence(timeout: 5))

        addAssetAccount(name: "Cuenta diaria", type: "Corriente", currency: "COP", balance: "1000000,50")
        addAssetAccount(name: "Fondo", type: "Ahorros", currency: "COP", balance: "250000,25")
        addAssetAccount(name: "Gastos China", type: "Corriente", currency: "CNY", balance: "125,50")
        addAssetAccount(name: "Reserva China", type: "Ahorros", currency: "CNY", balance: "50,25")

        assertMoney("checkingSubtotalCOP", contains: "1.000.000,50")
        assertMoney("savingsSubtotalCOP", contains: "250.000,25")
        assertMoney("totalAssetsCOP", contains: "1.250.000,75")
        assertMoney("checkingSubtotalCNY", contains: "125,50")
        assertMoney("savingsSubtotalCNY", contains: "50,25")
        assertMoney("totalAssetsCNY", contains: "175,75")

        // Edit every account attribute and verify that totals move between type/currency groups.
        let dailyRow = assetRow(named: "Cuenta diaria")
        reveal(dailyRow)
        dailyRow.tap()
        replaceText(in: "assetNameField", with: "Cuenta principal")
        replaceText(in: "assetBalanceField", with: "200,75")
        dismissAssetKeyboard()
        app.buttons["Ahorros"].tap()
        app.buttons["CNY"].tap()
        app.buttons["saveAssetAccountButton"].tap()
        XCTAssertTrue(app.buttons["addAssetAccountButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cuenta principal"].waitForExistence(timeout: 5))
        assertMoney("checkingSubtotalCOP", contains: "0,00")
        assertMoney("savingsSubtotalCOP", contains: "250.000,25")
        assertMoney("totalAssetsCOP", contains: "250.000,25")
        assertMoney("checkingSubtotalCNY", contains: "125,50")
        assertMoney("savingsSubtotalCNY", contains: "251,00")
        assertMoney("totalAssetsCNY", contains: "376,50")

        // Terminate and relaunch without resetting data: all edits and totals must persist.
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.navigationBars["Activos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cuenta principal"].waitForExistence(timeout: 5))
        assertMoney("totalAssetsCOP", contains: "250.000,25")
        assertMoney("totalAssetsCNY", contains: "376,50")

        let reserveRow = assetRow(named: "Reserva China")
        reveal(reserveRow)
        reserveRow.swipeLeft()
        app.buttons["Eliminar"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.alerts.firstMatch.staticTexts.element(boundBy: 1).label.contains("no se crean ingresos ni gastos"))
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(assetRow(named: "Reserva China").exists)

        reserveRow.swipeLeft()
        app.buttons["Eliminar"].tap()
        app.alerts.buttons["Eliminar cuenta"].tap()
        XCTAssertTrue(app.staticTexts["Reserva China"].waitForNonExistence(timeout: 5))
        assertMoney("savingsSubtotalCNY", contains: "200,75")
        assertMoney("totalAssetsCNY", contains: "326,25")

        // Manual asset records do not create planning periods or savings goals.
        openPeriods()
        XCTAssertTrue(element("periodsEmptyState").waitForExistence(timeout: 5))
        app.navigationBars.buttons["Planificación"].tap()
        element("goalsNavigationLink").tap()
        XCTAssertTrue(element("goalsEmptyState").waitForExistence(timeout: 5))
    }

    func testSavingsGoalCreateEditValidationProgressOptionalDateAndRelaunch() {
        launchResettingData()
        openGoals()

        app.buttons["addGoalButton"].tap()
        replaceText(in: "goalNameField", with: "Emergencia")
        replaceText(in: "goalTargetField", with: "0")
        app.buttons["saveGoalButton"].tap()
        XCTAssertTrue(element("goalFormError").waitForExistence(timeout: 3))
        XCTAssertTrue(element("goalFormError").label.contains("mayor que cero"))
        app.buttons["Cancelar"].tap()

        app.buttons["addGoalButton"].tap()
        replaceText(in: "goalNameField", with: "Emergencia")
        replaceText(in: "goalTargetField", with: "1000000")
        replaceText(in: "goalSavedField", with: "250000")
        replaceText(in: "goalAllocationField", with: "100000")
        app.buttons["saveGoalButton"].tap()
        let goalRow = element(prefix: "goalRow-")
        XCTAssertTrue(goalRow.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Emergencia"].exists)
        XCTAssertTrue(app.staticTexts["25 %"].exists)
        XCTAssertTrue(app.staticTexts["Sin fecha objetivo"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "250.000,00")).firstMatch.exists)

        goalRow.tap()
        replaceText(in: "goalNameField", with: "Fondo emergencia")
        replaceText(in: "goalSavedField", with: "500000")
        XCTAssertTrue(app.buttons["dismissGoalKeyboardButton"].waitForExistence(timeout: 2))
        app.buttons["dismissGoalKeyboardButton"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 2))
        app.switches["goalTargetDateToggle"]
            .coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            .tap()
        XCTAssertEqual(app.switches["goalTargetDateToggle"].value as? String, "1")
        app.buttons["saveGoalButton"].tap()
        XCTAssertTrue(app.buttons["addGoalButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fondo emergencia"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["50 %"].exists)
        XCTAssertTrue(app.staticTexts["Fecha objetivo"].exists)

        app.terminate()
        app.launchArguments = []
        app.launch()
        openGoals()
        XCTAssertTrue(app.staticTexts["Fondo emergencia"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["50 %"].exists)
        XCTAssertTrue(app.staticTexts["Fecha objetivo"].exists)

        let persistedGoal = element(prefix: "goalRow-")
        persistedGoal.swipeLeft()
        app.buttons["Eliminar"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(element(prefix: "goalRow-").exists)

        persistedGoal.swipeLeft()
        app.buttons["Eliminar"].tap()
        app.alerts.buttons["Eliminar meta"].tap()
        XCTAssertTrue(element("goalsEmptyState").waitForExistence(timeout: 5))
    }

    private func openPeriods() {
        app.tabBars.buttons["Planificación"].tap()
        XCTAssertTrue(element("periodsNavigationLink").waitForExistence(timeout: 5))
        element("periodsNavigationLink").tap()
        XCTAssertTrue(app.navigationBars["Períodos"].waitForExistence(timeout: 5))
    }

    private func openGoals() {
        app.tabBars.buttons["Planificación"].tap()
        XCTAssertTrue(element("goalsNavigationLink").waitForExistence(timeout: 5))
        element("goalsNavigationLink").tap()
        XCTAssertTrue(app.navigationBars["Metas de ahorro"].waitForExistence(timeout: 5))
    }

    private func addAssetAccount(name: String, type: String, currency: String, balance: String) {
        app.buttons["addAssetAccountButton"].tap()
        replaceText(in: "assetNameField", with: name)
        replaceText(in: "assetBalanceField", with: balance)
        dismissAssetKeyboard()
        app.buttons[type].tap()
        app.buttons[currency].tap()
        app.buttons["saveAssetAccountButton"].tap()
        XCTAssertTrue(app.buttons["addAssetAccountButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    private func dismissAssetKeyboard() {
        if app.keyboards.firstMatch.exists,
           element("dismissAssetKeyboardButton").waitForExistence(timeout: 2) {
            element("dismissAssetKeyboardButton").tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 2))
        }
    }

    private func assetRow(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "assetRow-", name))
            .firstMatch
    }

    private func assertMoney(_ identifier: String, contains amount: String) {
        let money = element(identifier)
        reveal(money)
        XCTAssertTrue(money.label.contains(amount), "Expected \(identifier) to contain \(amount), got \(money.label)")
    }

    private func reveal(_ target: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        if target.waitForExistence(timeout: 2), target.isHittable { return }
        for _ in 0..<5 {
            app.swipeUp()
            if target.exists, target.isHittable { return }
        }
        for _ in 0..<8 {
            app.swipeDown()
            if target.exists, target.isHittable { return }
        }
        XCTFail("Could not reveal \(target.identifier)", file: file, line: line)
    }

    private func launchResettingData() {
        app.launchArguments = ["-reset-local-data-for-ui-tests"]
        app.launch()
    }

    private func addIncome(_ amount: String) {
        app.buttons["addIncomeButton"].tap()
        replaceText(in: "incomeAmountField", with: amount)
        app.buttons["saveIncomeButton"].tap()
        XCTAssertTrue(app.buttons["addIncomeButton"].waitForExistence(timeout: 5))
    }

    private func replaceText(in identifier: String, with text: String) {
        let field = element(identifier)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Missing field \(identifier)")
        field.tap()
        if let value = field.value as? String, !value.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        field.typeText(text)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func element(prefix: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .firstMatch
    }
}
