import XCTest

@MainActor
final class ThereUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-ui-testing"]
        app.launch()
        app.activate()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testAddAndEditTibo() throws {
        let menu = app.statusItems.firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.click()
        let add = app.buttons["timezone.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.click()
        let tiboPreset = app.buttons["timezone.tibo"]
        XCTAssertTrue(tiboPreset.waitForExistence(timeout: 5))
        tiboPreset.click()
        let save = app.buttons["timezone.save"]
        XCTAssertTrue(save.isEnabled)
        save.click()
        let tibo = app.staticTexts["Tibo"]
        XCTAssertTrue(tibo.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Tibo").count, 1)
        tibo.click()
        XCTAssertTrue(app.staticTexts["编辑时区"].waitForExistence(timeout: 5))
        app.buttons["timezone.save"].click()
        XCTAssertTrue(tibo.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Tibo").count, 1)
    }
}
