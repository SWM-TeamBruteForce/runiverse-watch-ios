/// 폰에 보낸 명령이 어디까지 왔는지다. 조작 장 버튼의 잠금·문구를 정한다.
struct RunCommandState: Equatable {
    /// SYNC 답이나 보낸 명령의 결과를 기다린다.
    var isLocked = false
    /// 기다리는 명령이 종료다.
    var isFinishPending = false
    /// 명령을 보낸 지 3초가 넘었다.
    var isCommandOverdue = false
}

/// 조작 장 버튼이 부르는 폰 명령이다.
struct RunCommands {
    let pause: @MainActor () -> Void
    let resume: @MainActor () -> Void
    /// `forced`는 목표에 못 미쳐 끝내는지다 — 폰 종료 버튼과 같은 규칙이다.
    let finish: @MainActor (_ forced: Bool) -> Void
}
