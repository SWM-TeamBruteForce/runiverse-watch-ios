/// 워치가 폰으로 보내는 메시지다.
enum WatchMessage: Equatable {
    case sync(WatchSync)
    case pause(WatchPause)
    case resume(WatchResume)
    case finish(WatchFinish)
    case visibilityUpdate(WatchVisibilityUpdate)
}

/// 폰이 워치로 보내는 메시지다.
enum PhoneMessage: Equatable {
    case synced(WatchSynced)
    case stateUpdated(WatchStateUpdated)
    case comboTriggered(WatchComboTriggered)
    case error(PhoneError)
}

struct WatchSync: Encodable, Equatable {
    let syncId: String
    let watchVersion: String
}

/// 일시정지·재개·종료가 같이 싣는 값이다.
protocol WatchCommand {
    var requestId: String { get }
    var phoneInstanceId: String { get }
    var runningRoomId: Int64? { get }
    var statusVersion: Int { get }
}

struct WatchPause: WatchCommand, Equatable {
    let requestId: String
    let phoneInstanceId: String
    let runningRoomId: Int64?
    let statusVersion: Int
}

struct WatchResume: WatchCommand, Equatable {
    let requestId: String
    let phoneInstanceId: String
    let runningRoomId: Int64?
    let statusVersion: Int
}

struct WatchFinish: WatchCommand, Equatable {
    let requestId: String
    let phoneInstanceId: String
    let runningRoomId: Int64?
    let statusVersion: Int
    let forced: Bool
}

struct WatchVisibilityUpdate: Encodable, Equatable {
    let isVisible: Bool
}

// 상태 필드가 syncId와 같은 높이에 펼쳐져 온다 — 한 data에서 두 번 읽는다
struct WatchSynced: Equatable {
    let syncId: String
    let state: PhoneState
    let birthday: String?
    let photos: [PlayerPhoto]
}

extension WatchSynced: Decodable {
    private enum CodingKeys: String, CodingKey {
        case syncId, birthday, photos
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            syncId: try container.decode(String.self, forKey: .syncId),
            state: try PhoneState(from: decoder),
            birthday: try container.decodeIfPresent(String.self, forKey: .birthday),
            photos: try container.decodeIfPresent([PlayerPhoto].self, forKey: .photos) ?? []
        )
    }
}

struct WatchStateUpdated: Equatable {
    let state: PhoneState
}

struct WatchComboTriggered: Decodable, Equatable {
    let eventId: String
    let userId: String
    let comboCount: Int
    let kind: ComboKind
}

struct PhoneError: Decodable, Equatable {
    let code: String
    let message: String
    let sourceType: String
    let requestId: String?
}

struct PhoneState: Decodable, Equatable {
    let phoneInstanceId: String
    // 워치 실기기는 Int가 32비트라 끝없이 느는 번호는 Int64로 받는다
    let stateSequence: Int64
    let statusVersion: Int
    let lastRequestId: String?
    let run: RunState?
}

struct RunState: Decodable, Equatable {
    let runningRoomId: Int64?
    let type: RoomType
    let status: RunStatus
    let targetDistanceMeters: Int?
    let isServerConnected: Bool
    let isPenaltyApplicable: Bool
    let me: MyRecord
    let players: [Player]
    let finish: FinishProgress?
    let result: RunResult?
}

struct MyRecord: Decodable, Equatable {
    let distanceMeters: Int
    let elapsedSeconds: Int
    let currentPaceSecondsPerKm: Int?
    let caloriesKcal: Int?
    let cadenceSpm: Int?
}

struct Player: Decodable, Equatable {
    let userId: String
    let nickname: String
    let colorSlot: Int
    let distanceMeters: Int
    let currentPaceSecondsPerKm: Int?
    let status: RunStatus
    let gapMeters: Int?
    let comboCount: Int
    let maxComboCount: Int
    let isStale: Bool
}

struct FinishProgress: Decodable, Equatable {
    let stage: FinishStage
    let remainingMeters: Int?
}

struct RunResult: Decodable, Equatable {
    let isServerConfirmed: Bool
    let totalDistanceMeters: Int
    let averagePaceSecondsPerKm: Int?
    let elapsedSeconds: Int
}

struct PlayerPhoto: Decodable, Equatable {
    let userId: String
    let jpegBase64: String
}

enum RoomType: String, Decodable {
    case match = "MATCH"
    case solo = "SOLO"
    case invite = "INVITE"
}

enum RunStatus: String, Decodable {
    case running = "RUNNING"
    case paused = "PAUSED"
    case disconnected = "DISCONNECTED"
    case finished = "FINISHED"
}

enum FinishStage: String, Decodable {
    case finishing = "FINISHING"
    case goalPending = "GOAL_PENDING"
}

enum ComboKind: String, Decodable {
    case tick = "TICK"
    case milestone = "MILESTONE"
    case `break` = "BREAK"
}
