@testable import RuniverseWatch

// 기다리지 않고 맡긴 일을 시간 순서대로 그 자리에서 부른다
@MainActor
final class FakeTimer {
    private struct Work {
        let id: Int
        let dueTime: Duration
        let action: @MainActor () -> Void
    }

    private(set) var now = Duration.zero
    private var works: [Work] = []
    private var nextId = 0

    func schedule(after delay: Duration, _ action: @escaping @MainActor () -> Void) -> PhoneTimer {
        nextId += 1
        let id = nextId
        works.append(Work(id: id, dueTime: now + delay, action: action))
        return PhoneTimer { [weak self] in self?.works.removeAll { $0.id == id } }
    }

    // 부른 일이 새로 맡긴 일도 시간 안이면 이어서 부른다
    func advance(by duration: Duration) {
        let end = now + duration
        while let next = works.filter({ $0.dueTime <= end }).min(by: { ($0.dueTime, $0.id) < ($1.dueTime, $1.id) }) {
            works.removeAll { $0.id == next.id }
            now = next.dueTime
            next.action()
        }
        now = end
    }
}
