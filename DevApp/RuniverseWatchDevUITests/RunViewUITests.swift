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
    func testSwipeRightShowsControlsAndSwipeLeftReturns() {
        // given
        let app = launchRun("party")
        let pauseButton = app.buttons["일시정지"]
        XCTAssertFalse(pauseButton.exists && pauseButton.isHittable)

        // when
        app.swipeRight()

        // then
        XCTAssertTrue(waitUntilHittable(pauseButton))

        // when
        app.swipeLeft()

        // then
        XCTAssertTrue(waitUntilHittable(app.staticTexts["5'32\""]))
    }

    @MainActor
    func testComboEffectRowShowsAfterScrollingControls() {
        // given -> 콤보 칸은 어느 애플 화면에서도 스크롤해야 보인다
        let app = launchRun("party")
        app.swipeRight()
        XCTAssertTrue(waitUntilHittable(app.buttons["일시정지"]))
        let comboSwitch = app.switches["콤보 효과"]
        XCTAssertFalse(comboSwitch.exists && comboSwitch.isHittable)

        // when
        app.swipeUp()

        // then
        XCTAssertTrue(waitUntilHittable(comboSwitch))
    }

    @MainActor
    func testComboEffectSettingStaysAfterRelaunch() {
        // given
        var app = launchControls("party")
        app.swipeUp()
        XCTAssertTrue(waitUntilHittable(app.switches["콤보 효과"]))
        // 스위치 값은 켜짐 "1", 꺼짐 "0"이다
        let initialValue = app.switches["콤보 효과"].value as? String ?? ""
        let toggledValue = initialValue == "1" ? "0" : "1"

        // when
        app.switches["콤보 효과"].tap()
        XCTAssertTrue(waitUntilValue(app.switches["콤보 효과"], equals: toggledValue))
        app.terminate()
        app = launchControls("party")
        app.swipeUp()

        // then -> 워치에 저장한 값이라 다시 켜도 바뀐 채다
        XCTAssertTrue(waitUntilHittable(app.switches["콤보 효과"]))
        XCTAssertTrue(waitUntilValue(app.switches["콤보 효과"], equals: toggledValue))

        // when -> 다음 테스트를 위해 처음 값으로 되돌린다
        app.switches["콤보 효과"].tap()

        // then
        XCTAssertTrue(waitUntilValue(app.switches["콤보 효과"], equals: initialValue))
    }

    @MainActor
    func testPauseAndResumeFromControls() {
        // given
        let app = launchControls("party")

        // when
        app.buttons["일시정지"].tap()

        // then -> 가짜 폰이 멈춤을 반영해 보낸다
        XCTAssertTrue(waitUntilHittable(app.buttons["계속 달리기"]))

        // when
        app.buttons["계속 달리기"].tap()

        // then
        XCTAssertTrue(waitUntilHittable(app.buttons["일시정지"]))
    }

    @MainActor
    func testHoldingFinishEndsRun() {
        // given
        let app = launchControls("party")

        // when
        app.buttons["길게 눌러 종료"].press(forDuration: 1.6)

        // then
        XCTAssertTrue(app.staticTexts["러닝 완료"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testShortPressOnFinishAsksToHoldLonger() {
        // given
        let app = launchControls("party")

        // when
        app.buttons["길게 눌러 종료"].tap()

        // then -> 끝내지 않고 안내만 띄웠다가 되돌린다
        XCTAssertTrue(app.buttons["길게 눌러야 종료"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["길게 눌러 종료"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["러닝 완료"].exists)
    }

    @MainActor
    func testSwipeStartingOnFinishMovesPageWithoutFinishing() {
        // given
        let app = launchControls("party")
        let finishButton = app.buttons["길게 눌러 종료"]

        // when -> 종료 버튼을 누른 채 왼쪽으로 쓸어 첫 화면으로 넘긴다
        finishButton.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)))

        // then -> 끝내지 않고, 돌아와도 길게 누르라는 안내가 없다
        XCTAssertTrue(waitUntilHittable(app.staticTexts["5'32\""]))
        app.swipeRight()
        XCTAssertTrue(waitUntilHittable(finishButton))
        XCTAssertFalse(app.buttons["길게 눌러야 종료"].exists)
        XCTAssertFalse(app.staticTexts["러닝 완료"].exists)
    }

    @MainActor
    func testPausedFinishEndsRunWithOneTap() {
        // given
        let app = launchControls("paused")

        // when
        app.buttons["종료"].tap()

        // then
        XCTAssertTrue(app.staticTexts["러닝 완료"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testPhoneLostLocksControls() {
        // given -> 가짜 폰이 첫 답만 하고 조용해진다
        let app = launchRun("phoneLost")
        XCTAssertTrue(app.staticTexts["폰 연결 확인 중"].waitForExistence(timeout: 8))

        // when
        app.swipeRight()

        // then
        XCTAssertTrue(app.staticTexts["연결 후 조작 가능"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["일시정지"].isEnabled)
        XCTAssertFalse(app.buttons["길게 눌러 종료"].isEnabled)
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
    func testComboBurstCoversScreenAndCloses() {
        // given -> 가짜 폰은 3초마다 콤보를 올리고 1·3·5·10에서 큰 순간을 보낸다
        let app = launchRun("combo")
        let burst = comboBurst(in: app)

        // when & then
        XCTAssertTrue(burst.waitForExistence(timeout: 15))
        XCTAssertTrue(waitUntilGone(burst))
        XCTAssertTrue(waitUntilHittable(app.staticTexts["5'32\""]))
    }

    @MainActor
    func testComboBurstDoesNotShowOnControls() {
        // given
        let app = launchControls("combo")

        // when & then -> 큰 순간이 두 번 지나가는 동안 덮개가 버튼을 가리지 않는다
        XCTAssertFalse(comboBurst(in: app).waitForExistence(timeout: 13))
        XCTAssertTrue(app.buttons["일시정지"].isHittable)
    }

    // 큰 순간은 `N COMBO 이름` 하나로 읽힌다
    @MainActor
    private func comboBurst(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'COMBO'")).firstMatch
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

    // 멈춘 러닝은 첫 화면 페이스가 비어, 첫 화면 사진 칸의 첫 글자로 러닝 화면이 떴는지 본다
    @MainActor
    private func launchControls(_ fakeRun: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fakeRun", fakeRun]
        app.launch()
        XCTAssertTrue(app.staticTexts["완"].waitForExistence(timeout: 5))
        dismissHealthPermissionIfShown()
        app.swipeRight()
        XCTAssertTrue(waitUntilHittable(app.buttons[fakeRun == "paused" ? "계속 달리기" : "일시정지"]))
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

    @MainActor
    private func waitUntilGone(_ element: XCUIElement) -> Bool {
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 3) == .completed
    }

    @MainActor
    private func waitUntilValue(_ element: XCUIElement, equals value: String) -> Bool {
        let hasValue = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: hasValue, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: 3) == .completed
    }
}
