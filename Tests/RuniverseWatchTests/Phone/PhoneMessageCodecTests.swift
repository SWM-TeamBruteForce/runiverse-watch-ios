import Foundation
import Testing

@testable import RuniverseWatch

struct PhoneMessageCodecTests {

    @Test
    func `상태 메시지를 문서의 모양 그대로 읽는다`() throws {
        // given
        let body = """
            {"event":"WATCH_STATE_UPDATED","data":{
              "phoneInstanceId":"3f2a9c1e","stateSequence":1532,"statusVersion":4,"lastRequestId":"b71d0e42",
              "run":{
                "runningRoomId":812,"type":"MATCH","status":"RUNNING","targetDistanceMeters":5000,
                "isServerConnected":true,"isPenaltyApplicable":true,
                "me":{"distanceMeters":3421,"elapsedSeconds":1450,"currentPaceSecondsPerKm":332,
                      "caloriesKcal":210,"cadenceSpm":172},
                "players":[{"userId":"u2","nickname":"콩나물","colorSlot":1,"distanceMeters":3541,
                            "currentPaceSecondsPerKm":318,"status":"RUNNING","gapMeters":120,
                            "comboCount":12,"maxComboCount":20,"isStale":false}],
                "finish":{"stage":"GOAL_PENDING","remainingMeters":420},
                "result":null
              }
            }}
            """

        // when
        let message = try PhoneMessageCodec.decode(Data(body.utf8))

        // then
        let expected = PhoneMessage.stateUpdated(
            WatchStateUpdated(
                state: PhoneState(
                    phoneInstanceId: "3f2a9c1e",
                    stateSequence: 1532,
                    statusVersion: 4,
                    lastRequestId: "b71d0e42",
                    run: RunState(
                        runningRoomId: 812,
                        type: .match,
                        status: .running,
                        targetDistanceMeters: 5000,
                        isServerConnected: true,
                        isPenaltyApplicable: true,
                        me: MyRecord(
                            distanceMeters: 3421,
                            elapsedSeconds: 1450,
                            currentPaceSecondsPerKm: 332,
                            caloriesKcal: 210,
                            cadenceSpm: 172
                        ),
                        players: [
                            Player(
                                userId: "u2",
                                nickname: "콩나물",
                                colorSlot: 1,
                                distanceMeters: 3541,
                                currentPaceSecondsPerKm: 318,
                                status: .running,
                                gapMeters: 120,
                                comboCount: 12,
                                maxComboCount: 20,
                                isStale: false
                            )
                        ],
                        finish: FinishProgress(stage: .goalPending, remainingMeters: 420),
                        result: nil
                    )
                )
            )
        )
        #expect(message == expected)
    }

    @Test
    func `방 번호 없는 러닝은 방 번호를 nil로 읽는다`() throws {
        // given
        let body = """
            {"event":"WATCH_STATE_UPDATED","data":{
              "phoneInstanceId":"p1","stateSequence":1,"statusVersion":0,"lastRequestId":null,
              "run":{
                "runningRoomId":null,"type":"SOLO","status":"RUNNING","targetDistanceMeters":null,
                "isServerConnected":false,"isPenaltyApplicable":false,
                "me":{"distanceMeters":0,"elapsedSeconds":1},
                "players":[],"finish":null,"result":null
              }
            }}
            """

        // when
        let message = try PhoneMessageCodec.decode(Data(body.utf8))

        // then
        let expected = PhoneMessage.stateUpdated(
            WatchStateUpdated(
                state: PhoneState(
                    phoneInstanceId: "p1",
                    stateSequence: 1,
                    statusVersion: 0,
                    lastRequestId: nil,
                    run: RunState(
                        runningRoomId: nil,
                        type: .solo,
                        status: .running,
                        targetDistanceMeters: nil,
                        isServerConnected: false,
                        isPenaltyApplicable: false,
                        me: MyRecord(
                            distanceMeters: 0,
                            elapsedSeconds: 1,
                            currentPaceSecondsPerKm: nil,
                            caloriesKcal: nil,
                            cadenceSpm: nil
                        ),
                        players: [],
                        finish: nil,
                        result: nil
                    )
                )
            )
        )
        #expect(message == expected)
    }

    @Test
    func `파티원 흐림을 사람별로 읽는다`() throws {
        // given
        let body = """
            {"event":"WATCH_STATE_UPDATED","data":{
              "phoneInstanceId":"p1","stateSequence":1,"statusVersion":0,
              "run":{
                "runningRoomId":812,"type":"MATCH","status":"RUNNING",
                "isServerConnected":true,"isPenaltyApplicable":true,
                "me":{"distanceMeters":0,"elapsedSeconds":1},
                "players":[
                  {"userId":"u2","nickname":"콩나물","colorSlot":1,"distanceMeters":0,"status":"RUNNING",
                   "comboCount":0,"maxComboCount":0,"isStale":true},
                  {"userId":"u3","nickname":"두부","colorSlot":2,"distanceMeters":0,"status":"RUNNING",
                   "comboCount":0,"maxComboCount":0,"isStale":false}
                ]
              }
            }}
            """

        // when
        let message = try PhoneMessageCodec.decode(Data(body.utf8))

        // then
        guard case .stateUpdated(let stateUpdated) = message else {
            Issue.record("상태 메시지가 아님: \(String(describing: message))")
            return
        }
        let staleByUserId = stateUpdated.state.run?.players.map { "\($0.userId):\($0.isStale)" }
        #expect(staleByUserId == ["u2:true", "u3:false"])
    }

    @Test
    func `SYNCED는 같은 높이의 상태 필드와 사진·생일을 함께 읽는다`() throws {
        // given
        let body = """
            {"event":"WATCH_SYNCED","data":{
              "syncId":"s1","phoneInstanceId":"p1","stateSequence":7,"statusVersion":0,"lastRequestId":null,
              "run":null,"birthday":"1999-03-02","photos":[{"userId":"u2","jpegBase64":"/9j/"}]
            }}
            """

        // when
        let message = try PhoneMessageCodec.decode(Data(body.utf8))

        // then
        let expected = PhoneMessage.synced(
            WatchSynced(
                syncId: "s1",
                state: PhoneState(
                    phoneInstanceId: "p1",
                    stateSequence: 7,
                    statusVersion: 0,
                    lastRequestId: nil,
                    run: nil
                ),
                birthday: "1999-03-02",
                photos: [PlayerPhoto(userId: "u2", jpegBase64: "/9j/")]
            )
        )
        #expect(message == expected)
    }

    @Test
    func `모르는 필드는 무시한다`() throws {
        // given
        let body = """
            {"event":"WATCH_COMBO_TRIGGERED","data":{
              "eventId":"e1","userId":"u2","comboCount":3,"kind":"MILESTONE","newField":1
            }}
            """

        // when
        let message = try PhoneMessageCodec.decode(Data(body.utf8))

        // then
        let expected = PhoneMessage.comboTriggered(
            WatchComboTriggered(eventId: "e1", userId: "u2", comboCount: 3, kind: .milestone)
        )
        #expect(message == expected)
    }

    @Test
    func `모르는 event는 nil을 돌려준다`() throws {
        // given
        let body = #"{"event":"WATCH_SOMETHING_NEW","data":{}}"#

        // when
        let message = try PhoneMessageCodec.decode(Data(body.utf8))

        // then
        #expect(message == nil)
    }

    @Test(
        arguments: [
            "not json",
            #"{"data":{}}"#,
            #"{"event":"ERROR"}"#,
            #"{"event":"WATCH_STATE_UPDATED","data":{"phoneInstanceId":"p1"}}"#,
            #"{"event":"WATCH_COMBO_TRIGGERED","data":{"eventId":"e1","userId":"u2","comboCount":3,"kind":"NEW"}}"#,
        ]
    )
    func `깨진 본문은 DecodingError를 던진다`(body: String) {
        // when & then
        #expect(throws: DecodingError.self) { try PhoneMessageCodec.decode(Data(body.utf8)) }
    }

    @Test
    func `SYNC는 워치 버전을 함께 쓴다`() throws {
        // given
        let message = WatchMessage.sync(WatchSync(syncId: "s1", watchVersion: "1.0.0"))

        // when
        let body = try PhoneMessageCodec.encode(message)

        // then
        #expect(try json(body) == json(#"{"event":"WATCH_SYNC","data":{"syncId":"s1","watchVersion":"1.0.0"}}"#))
    }

    @Test
    func `종료 명령을 봉투에 담아 쓴다`() throws {
        // given
        let message = WatchMessage.finish(
            WatchFinish(requestId: "r1", phoneInstanceId: "p1", runningRoomId: 812, statusVersion: 4, forced: false)
        )

        // when
        let body = try PhoneMessageCodec.encode(message)

        // then
        let expected = """
            {"event":"WATCH_FINISH","data":\
            {"requestId":"r1","phoneInstanceId":"p1","runningRoomId":812,"statusVersion":4,"forced":false}}
            """
        #expect(try json(body) == json(expected))
    }

    @Test
    func `방 번호가 없는 명령은 필드를 빼지 않고 null로 쓴다`() throws {
        // given
        let messages: [WatchMessage] = [
            .pause(WatchPause(requestId: "r1", phoneInstanceId: "p1", runningRoomId: nil, statusVersion: 4)),
            .resume(WatchResume(requestId: "r1", phoneInstanceId: "p1", runningRoomId: nil, statusVersion: 4)),
            .finish(
                WatchFinish(requestId: "r1", phoneInstanceId: "p1", runningRoomId: nil, statusVersion: 4, forced: true)
            ),
        ]

        // when
        let bodies = try messages.map { try json(PhoneMessageCodec.encode($0)) }

        // then
        let common = #""requestId":"r1","phoneInstanceId":"p1","runningRoomId":null,"statusVersion":4"#
        let expected = try [
            json(#"{"event":"WATCH_PAUSE","data":{\#(common)}}"#),
            json(#"{"event":"WATCH_RESUME","data":{\#(common)}}"#),
            json(#"{"event":"WATCH_FINISH","data":{\#(common),"forced":true}}"#),
        ]
        #expect(bodies == expected)
    }

    // 키 순서는 JSON에서 뜻이 없어, 폰이 읽는 것처럼 풀어서 비교한다
    private func json(_ body: Data) throws -> NSDictionary {
        try #require(JSONSerialization.jsonObject(with: body) as? NSDictionary)
    }

    private func json(_ body: String) throws -> NSDictionary {
        try json(Data(body.utf8))
    }
}
