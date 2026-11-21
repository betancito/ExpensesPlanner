import XCTest
@testable import ExpensesPlanner

final class ExpensesPlannerTests: XCTestCase {
    func testProvisionalLaunchContentUsesExpectedCopy() {
        XCTAssertEqual(ContentView.title, "ExpensesPlanner")
        XCTAssertEqual(ContentView.message, "Your expense planning workspace is ready.")
    }
}
