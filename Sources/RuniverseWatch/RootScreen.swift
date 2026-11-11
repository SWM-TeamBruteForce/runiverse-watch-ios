/// 맨 위 화면이 띄울 화면이다.
enum RootScreen: Equatable {
    case run(RunState)
    case updateRequired
    case runSummary(RunState)
    case idle(isPhoneReachable: Bool)

    init(_ linkState: PhoneLinkState) {
        if linkState.isRunActive, let run = linkState.phoneState?.run {
            self = .run(run)
        } else if linkState.isUpdateRequired {
            self = .updateRequired
        } else if let finishedRun = linkState.finishedRun {
            self = .runSummary(finishedRun)
        } else {
            self = .idle(isPhoneReachable: linkState.isPhoneReachable)
        }
    }
}
