import XCTest

final class RunViewUITests: XCTestCase {

    @MainActor
    func testRunScreenShowsWhenPhoneSendsRun() {
        // given
        let app = XCUIApplication()
        app.launchArguments = ["-fakeRun", "party"]

        // when
        app.launch()

        // then -> 샘플 내 페이스가 첫 화면 가운데에 뜬다
        XCTAssertTrue(app.staticTexts["5'32\""].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["폰에서 러닝 시작"].exists)
    }

    @MainActor
    func testSwipeMovesBetweenOverviewAndMyRecord() {
        // given
        let app = XCUIApplication()
        app.launchArguments = ["-fakeRun", "party"]
        app.launch()
        let pace = app.staticTexts["5'32\""]
        let cadenceUnit = app.staticTexts["spm"]
        XCTAssertTrue(pace.waitForExistence(timeout: 5))
        XCTAssertFalse(cadenceUnit.exists && cadenceUnit.isHittable)

        // when
        app.swipeLeft()

        // then
        XCTAssertTrue(waitUntilHittable(cadenceUnit))

        // when
        app.swipeRight()

        // then
        XCTAssertTrue(waitUntilHittable(pace))
    }

    @MainActor
    func testPhoneLostShowsNoticeAndKeepsRunScreen() {
        // given -> 가짜 폰이 첫 답만 하고 조용해진다
        let app = XCUIApplication()
        app.launchArguments = ["-fakeRun", "phoneLost"]

        // when
        app.launch()

        // then -> 3초 감시가 끊김으로 보고 안내를 띄운다
        XCTAssertTrue(app.staticTexts["폰 연결 확인 중"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["5'32\""].exists)
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement) -> Bool {
        let hittable = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: hittable, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 3) == .completed
    }
}
