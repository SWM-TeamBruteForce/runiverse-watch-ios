import Foundation

/// 메시지 본문 `{"event": ..., "data": {...}}`과 메시지 값을 바꾼다.
///
/// 깨진 본문은 `DecodingError`를 던진다.
enum PhoneMessageCodec {

    static func encode(_ message: WatchMessage) throws -> Data {
        let encoder = JSONEncoder()
        return switch message {
        case .sync(let sync): try encoder.encode(Envelope(event: message.event, data: sync))
        case .pause(let pause): try encoder.encode(Envelope(event: message.event, data: CommandData(pause)))
        case .resume(let resume): try encoder.encode(Envelope(event: message.event, data: CommandData(resume)))
        case .finish(let finish):
            try encoder.encode(Envelope(event: message.event, data: CommandData(finish, forced: finish.forced)))
        case .visibilityUpdate(let visibilityUpdate):
            try encoder.encode(Envelope(event: message.event, data: visibilityUpdate))
        }
    }

    /// 모르는 event면 nil이다 — 폰 앱이 먼저 업데이트된 경우다.
    static func decode(_ body: Data) throws -> PhoneMessage? {
        // JSONDecoder는 모르는 필드를 무시해, 폰 앱이 새 필드를 먼저 보내도 읽힌다
        let decoder = JSONDecoder()
        let event = try decoder.decode(EventOnly.self, from: body).event
        switch event {
        case "WATCH_SYNCED":
            return .synced(try decoder.decode(DataOnly<WatchSynced>.self, from: body).data)
        case "WATCH_STATE_UPDATED":
            let state = try decoder.decode(DataOnly<PhoneState>.self, from: body).data
            return .stateUpdated(WatchStateUpdated(state: state))
        case "WATCH_COMBO_TRIGGERED":
            return .comboTriggered(try decoder.decode(DataOnly<WatchComboTriggered>.self, from: body).data)
        case "ERROR":
            return .error(try decoder.decode(DataOnly<PhoneError>.self, from: body).data)
        default:
            return nil
        }
    }

    private struct Envelope<Body: Encodable>: Encodable {
        let event: String
        let data: Body
    }

    private struct EventOnly: Decodable {
        let event: String
    }

    private struct DataOnly<Body: Decodable>: Decodable {
        let data: Body
    }

    private struct CommandData: Encodable {
        let command: any WatchCommand
        let forced: Bool?

        init(_ command: any WatchCommand, forced: Bool? = nil) {
            self.command = command
            self.forced = forced
        }

        // 자동 생성 코드는 nil인 키를 빼서, 방 번호 null을 남기려고 직접 쓴다
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(command.requestId, forKey: .requestId)
            try container.encode(command.phoneInstanceId, forKey: .phoneInstanceId)
            try container.encode(command.runningRoomId, forKey: .runningRoomId)
            try container.encode(command.statusVersion, forKey: .statusVersion)
            try container.encodeIfPresent(forced, forKey: .forced)
        }

        private enum CodingKeys: String, CodingKey {
            case requestId, phoneInstanceId, runningRoomId, statusVersion, forced
        }
    }
}

extension WatchMessage {
    /// 봉투의 event 이름이다. 로그에도 이 이름만 남긴다.
    var event: String {
        switch self {
        case .sync: "WATCH_SYNC"
        case .pause: "WATCH_PAUSE"
        case .resume: "WATCH_RESUME"
        case .finish: "WATCH_FINISH"
        case .visibilityUpdate: "WATCH_VISIBILITY_UPDATE"
        }
    }
}
