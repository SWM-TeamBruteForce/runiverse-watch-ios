import XCTest

final class IdleViewUITests: XCTestCase {

    @MainActor
    func testIdleShowsOnlyMarkUntilPhoneCheckingWithoutPhone() {
        // given
        let app = XCUIApplication()

        // when
        app.launch()

        // then -> 개발용 앱은 폰 앱이 없는 워치 전용 앱이라 SYNC 답이 오지 않는다
        XCTAssertTrue(app.images["Runiverse"].waitForExistence(timeout: 1))
        XCTAssertFalse(app.staticTexts["폰에서 러닝 시작"].exists)
        XCTAssertFalse(app.staticTexts["폰 연결 확인 중"].exists)
        XCTAssertTrue(app.staticTexts["폰 연결 확인 중"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["폰에서 러닝 시작"].exists)
    }
}
