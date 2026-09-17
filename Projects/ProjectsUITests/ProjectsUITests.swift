import XCTest

final class ProjectsUITests: XCTestCase {
    func testMainWindowExists() throws {
        let app = XCUIApplication()
        app.launchEnvironment["PROJECTS_CI_SCREENSHOT"] = "1"
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "main-window"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
