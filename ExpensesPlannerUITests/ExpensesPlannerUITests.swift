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
        XCTAssertTrue(app.navigationBars["Mi plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("periodsEmptyState").exists)
        XCTAssertTrue(app.buttons["Nuevo período"].exists)

        app.tabBars.buttons["Metas"].tap()
        XCTAssertTrue(app.navigationBars["Metas de ahorro"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("goalsEmptyState").exists)
        XCTAssertTrue(app.buttons["Nueva meta"].exists)
    }

    func testPeriodIncomeAndObligationCRUDValidationTotalsAndRelaunch() {
        launchResettingData()

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
        let persistedPeriod = element(prefix: "periodRow-")
        XCTAssertTrue(persistedPeriod.waitForExistence(timeout: 5))
        persistedPeriod.tap()
        XCTAssertTrue(element("confirmedIncomeTotal").waitForExistence(timeout: 5))
        XCTAssertTrue(element("confirmedIncomeTotal").label.contains("1.600.000,00"))
        XCTAssertTrue(element("obligationsTotal").label.contains("300.000,00"))
        XCTAssertTrue(element("remainingFlexibleTotal").label.contains("1.300.000,00"))
        XCTAssertTrue(app.staticTexts["Arriendo"].exists)

        app.navigationBars.buttons["Mi plan"].tap()
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

    func testSavingsGoalCreateEditValidationProgressOptionalDateAndRelaunch() {
        launchResettingData()
        app.tabBars.buttons["Metas"].tap()

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
        app.tabBars.buttons["Metas"].tap()
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
