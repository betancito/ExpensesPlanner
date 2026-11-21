import XCTest

final class ExpensesPlannerUITests: XCTestCase {
    func testLaunchDisplaysProvisionalScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertEqual(app.state, .runningForeground)

        let title = app.staticTexts["provisionalTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "ExpensesPlanner")
        XCTAssertTrue(app.staticTexts["provisionalMessage"].exists)
    }
}
