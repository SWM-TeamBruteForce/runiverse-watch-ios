import XCTest

final class RunSummaryViewUITests: XCTestCase {

    @MainActor
    func testCloseShowsIdleScreen() {
        // given
        let app = launchSummary("summary")

        // when
        app.buttons["닫기"].tap()

        // then -> 가짜 폰이 같은 끝난 상태를 1초마다 다시 보내도 결과를 다시 띄우지 않는다
        XCTAssertTrue(app.staticTexts["폰에서 러닝 시작"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["러닝 완료"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCloseWhileResultPendingShowsIdleScreen() {
        // given
        let app = launchSummary("summaryPending")

        // when
        app.buttons["닫기"].tap()

        // then
        XCTAssertTrue(app.staticTexts["폰에서 러닝 시작"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["러닝 완료"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPhoneLostWhileResultPendingShowsNotice() {
        // given -> 가짜 폰이 결과 없는 끝난 상태로 첫 답만 하고 조용해진다
        let app = launchSummary("summaryPhoneLost")

        // when & then -> 결과를 기다린 지 13초가 넘으면 제목 자리에 안내를 띄우고 닫기는 남긴다
        XCTAssertTrue(app.staticTexts["폰 연결 확인 중"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.staticTexts["러닝 완료"].exists)
        XCTAssertTrue(app.buttons["닫기"].exists)
    }

    @MainActor
    private func launchSummary(_ fakeRun: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fakeRun", fakeRun]
        app.launch()
        XCTAssertTrue(app.staticTexts["러닝 완료"].waitForExistence(timeout: 5))
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
}
