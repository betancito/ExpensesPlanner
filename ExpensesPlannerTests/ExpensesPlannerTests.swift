import XCTest
@testable import ExpensesPlanner

final class ExpensesPlannerTests: XCTestCase {
    func testAssetLaunchContentUsesSpanishTitle() {
        XCTAssertEqual(ContentView.title, "Activos")
    }
}
