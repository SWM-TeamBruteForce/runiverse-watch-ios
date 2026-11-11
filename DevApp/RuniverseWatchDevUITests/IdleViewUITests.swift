import XCTest

final class IdleViewUITests: XCTestCase {

    @MainActor
    func testIdleTurnsToPhoneCheckingWithoutPhone() {
        // given
        let app = XCUIApplication()

        // when
        app.launch()

        // then -> 개발용 앱은 짝지은 폰이 없어 SYNC 답이 오지 않는다
        XCTAssertTrue(app.staticTexts["폰에서 러닝 시작"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["폰 연결 확인 중"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["폰에서 러닝 시작"].exists)
    }

    @MainActor
    func testIdleStaysOpenWhenSwipedRight() {
        // given
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.images["Runiverse"].waitForExistence(timeout: 1))

        // when
        app.swipeRight()

        // then
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.images["Runiverse"].exists)
    }
}
