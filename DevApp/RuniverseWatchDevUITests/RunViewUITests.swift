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
        dismissHealthPermissionIfShown()
        XCTAssertTrue(waitUntilHittable(pace))
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
        dismissHealthPermissionIfShown()

        // then -> 3초 감시가 끊김으로 보고 안내를 띄운다
        XCTAssertTrue(app.staticTexts["폰 연결 확인 중"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["5'32\""].exists)
    }

    @MainActor
    func testSwipeUpMovesThroughPlayerPagesAndSwipeDownReturns() {
        // given -> 첫 화면 사진 칸의 첫 글자는 첫 화면에만 있다
        let app = launchRun("party")
        let overviewInitial = app.staticTexts["완"]

        // when
        app.swipeUp()

        // then -> 파티원 장 위 줄에 그 사람 이름이 뜬다
        XCTAssertTrue(waitUntilHittable(app.staticTexts["완두콩"]))

        // when
        app.swipeUp()

        // then
        XCTAssertTrue(waitUntilHittable(app.staticTexts["콩나물"]))

        // when
        app.swipeDown()
        app.swipeDown()

        // then
        XCTAssertTrue(waitUntilHittable(overviewInitial))
    }

    @MainActor
    func testPlayerPageDoesNotMoveSideways() {
        // given
        let app = launchRun("party")
        let cadenceUnit = app.staticTexts["spm"]
        app.swipeUp()
        XCTAssertTrue(waitUntilHittable(app.staticTexts["완두콩"]))

        // when
        app.swipeLeft()

        // then -> 내 기록 장으로 넘어가지 않는다
        XCTAssertFalse(waitUntilHittable(cadenceUnit))
        XCTAssertTrue(app.staticTexts["완두콩"].isHittable)

        // when -> 첫 화면으로 돌아오면 다시 좌우로 넘어간다
        app.swipeDown()
        XCTAssertTrue(waitUntilHittable(app.staticTexts["완"]))
        app.swipeLeft()

        // then
        XCTAssertTrue(waitUntilHittable(cadenceUnit))
    }

    @MainActor
    func testSoloStaysOnOverviewWhenSwipedUp() {
        // given
        let app = launchRun("solo")

        // when
        app.swipeUp()

        // then
        XCTAssertTrue(waitUntilHittable(app.staticTexts["5'32\""]))
    }

    @MainActor
    private func launchRun(_ fakeRun: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fakeRun", fakeRun]
        app.launch()
        XCTAssertTrue(app.staticTexts["5'32\""].waitForExistence(timeout: 5))
        dismissHealthPermissionIfShown()
        return app
    }

    // 새 시뮬레이터는 건강 권한 창을 시스템 화면으로 띄워 앱을 가린다 — 한 번 닫으면 다시 안 묻는다
    @MainActor
    private func dismissHealthPermissionIfShown() {
        let closeButton = XCUIApplication(bundleIdentifier: "com.apple.Carousel")
            .navigationBars["NanoHealthPrivacyAlertBundle.InitialView"].buttons.firstMatch
        if closeButton.waitForExistence(timeout: 3) { closeButton.tap() }
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement) -> Bool {
        let hittable = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: hittable, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 3) == .completed
    }
}
