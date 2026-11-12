/// 미리보기와 가짜 폰이 쓰는 러닝 상태다.
enum RunSamples {
    static let party = run()

    static let solo = run(type: .solo, targetDistanceMeters: nil, isPenaltyApplicable: false, players: [])

    static let longValues = run(
        targetDistanceMeters: 42_195,
        me: MyRecord(
            distanceMeters: 42_100,
            elapsedSeconds: 17_999,
            currentPaceSecondsPerKm: 605,
            caloriesKcal: me.caloriesKcal,
            cadenceSpm: me.cadenceSpm
        ),
        players: players.map { player($0, gapMeters: 9_999) }
    )

    static let paused = run(status: .paused)

    static let playerStatuses = run(
        players: zip(players, [RunStatus.paused, .disconnected, .finished]).map { player($0, status: $1) }
    )

    static let serverLost = run(isServerConnected: false)

    /// 파티원 장 끝 경우다 — 가장 넓은 값, 통지 전, 격차 0·소식 늦음.
    static let partyEdges = run(players: [longestPlayer, notNotifiedPlayer, levelStalePlayer])

    /// 폰 프로필 API 모양 그대로다. 만 나이로 심박 구간을 잰다.
    static let birthday = "1995-03-10"

    private static let me = MyRecord(
        distanceMeters: 3421,
        elapsedSeconds: 1450,
        currentPaceSecondsPerKm: 332,
        caloriesKcal: 210,
        cadenceSpm: 172
    )

    private static let players = [
        newPlayer(userId: "u1", nickname: "완두콩", colorSlot: 1, gapMeters: 120, status: .running, comboCount: 0),
        newPlayer(userId: "u2", nickname: "콩나물", colorSlot: 2, gapMeters: -20, status: .running, comboCount: 12),
        newPlayer(userId: "u3", nickname: "강낭콩", colorSlot: 3, gapMeters: -600, status: .paused, comboCount: 0),
    ]

    // 격차 `뒤 400m`이 가운데 글자로 가장 넓고, 원래 폭 페이스는 `40'00"`이 가장 넓다
    private static let longestPlayer = Player(
        userId: "u1",
        nickname: "가나다라마바사아자차카",
        colorSlot: 1,
        distanceMeters: 42_100,
        currentPaceSecondsPerKm: 2400,
        status: .running,
        gapMeters: -400,
        comboCount: 0,
        maxComboCount: 888,
        isStale: false
    )

    // 폰은 통지 전 파티원을 화면이 그리는 값(거리 0·이름 `함께 달리는 사람`)으로 보낸다
    private static let notNotifiedPlayer = Player(
        userId: "u2",
        nickname: "함께 달리는 사람",
        colorSlot: 2,
        distanceMeters: 0,
        currentPaceSecondsPerKm: nil,
        status: .running,
        gapMeters: nil,
        comboCount: 0,
        maxComboCount: 0,
        isStale: false
    )

    private static let levelStalePlayer = Player(
        userId: "u3",
        nickname: "콩나물",
        colorSlot: 3,
        distanceMeters: me.distanceMeters,
        currentPaceSecondsPerKm: 332,
        status: .running,
        gapMeters: 0,
        comboCount: 12,
        maxComboCount: 20,
        isStale: true
    )

    private static func run(
        type: RoomType = .match,
        status: RunStatus = .running,
        targetDistanceMeters: Int? = 5000,
        isServerConnected: Bool = true,
        isPenaltyApplicable: Bool = true,
        me: MyRecord = me,
        players: [Player] = players
    ) -> RunState {
        RunState(
            runningRoomId: 812,
            type: type,
            status: status,
            targetDistanceMeters: targetDistanceMeters,
            isServerConnected: isServerConnected,
            isPenaltyApplicable: isPenaltyApplicable,
            me: me,
            players: players,
            finish: nil,
            result: nil
        )
    }

    private static func newPlayer(
        userId: String,
        nickname: String,
        colorSlot: Int,
        gapMeters: Int,
        status: RunStatus,
        comboCount: Int
    ) -> Player {
        Player(
            userId: userId,
            nickname: nickname,
            colorSlot: colorSlot,
            distanceMeters: me.distanceMeters + gapMeters,
            currentPaceSecondsPerKm: 318,
            status: status,
            gapMeters: gapMeters,
            comboCount: comboCount,
            maxComboCount: 20,
            isStale: false
        )
    }

    private static func player(_ base: Player, gapMeters: Int? = nil, status: RunStatus? = nil) -> Player {
        let gapMeters = gapMeters ?? base.gapMeters
        return Player(
            userId: base.userId,
            nickname: base.nickname,
            colorSlot: base.colorSlot,
            distanceMeters: me.distanceMeters + (gapMeters ?? 0),
            currentPaceSecondsPerKm: base.currentPaceSecondsPerKm,
            status: status ?? base.status,
            gapMeters: gapMeters,
            comboCount: base.comboCount,
            maxComboCount: base.maxComboCount,
            isStale: base.isStale
        )
    }
}
