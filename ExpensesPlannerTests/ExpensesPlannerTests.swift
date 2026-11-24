import XCTest
@testable import ExpensesPlanner

final class ExpensesPlannerTests: XCTestCase {
    func testManagementLaunchContentUsesSpanishTitle() {
        XCTAssertEqual(ContentView.title, "Mi plan")
    }
}
