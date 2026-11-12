/// 맨 위 화면이 띄울 화면이다.
enum RootScreen: Equatable {
    case run(RunState)
    case updateRequired
    case awaitingPhone
    case runSummary(RunState)
    case idle(isPhoneReachable: Bool)

    init(_ linkState: PhoneLinkState) {
        if linkState.isRunActive, let run = linkState.phoneState?.run {
            self = .run(run)
        } else if linkState.isUpdateRequired {
            self = .updateRequired
        } else if linkState.isAwaitingRun, linkState.isPhoneReachable {
            // 폰 상태가 오기 전 `폰에서 러닝 시작`이 잠깐 끼지 않게, 끊김 판정 전까지 기다린다
            self = .awaitingPhone
        } else if let finishedRun = linkState.finishedRun {
            self = .runSummary(finishedRun)
        } else if linkState.isSyncing, linkState.isPhoneReachable {
            // 폰이 답하기 전엔 폰 앱이 떠 있는지 몰라, 끊김 판정 전까지 문구 없이 그린다
            self = .awaitingPhone
        } else {
            self = .idle(isPhoneReachable: linkState.isPhoneReachable)
        }
    }
}
