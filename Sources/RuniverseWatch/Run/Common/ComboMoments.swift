import Foundation
import Observation

/// 콤보 순간을 받아 화면에 띄울 순간을 고른다. 진동은 `RunVibrator`가 따로 울린다.
@MainActor
@Observable
final class ComboMoments {
    /// 사람 번호마다 지금 띄우는 작은 순간이다. 한 통지에 여러 사람이 함께 오른다.
    private(set) var smallMoments: [String: ComboMoment] = [:]
    /// 지금 화면을 덮는 큰 순간이다.
    private(set) var burst: ComboBurst?

    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let schedule: PhoneSchedule
    @ObservationIgnored private let isEffectOn: () -> Bool
    @ObservationIgnored private var isScreenActive = false
    @ObservationIgnored private var isControlsShown = false

    /// `now`·`schedule`은 테스트가 시간을 직접 흘리려고, `isEffectOn`은 저장 값 대신 바꿔 끼운다.
    init(
        now: @escaping () -> Date = { Date() },
        schedule: @escaping PhoneSchedule = PhoneLink.sleepThenRun,
        isEffectOn: @escaping () -> Bool = { ComboEffectSetting.isOn() }
    ) {
        self.now = now
        self.schedule = schedule
        self.isEffectOn = isEffectOn
    }

    func onCombo(_ combo: WatchComboTriggered, linkState: PhoneLinkState) {
        // 어둡거나 꺼진 화면에 온 콤보는 진동만 한다 — 켜진 뒤 효과를 뒤늦게 틀지 않는다
        guard isScreenActive else { return }
        switch ComboMomentSize(kind: combo.kind, isEffectOn: isEffectOn()) {
        case .small:
            showSmall(combo)
        case .big:
            // 명단에 없는 사람은 띄울 사진·이름이 없어 진동만 한다
            guard linkState.isRunActive,
                linkState.phoneState?.run?.players.contains(where: { $0.userId == combo.userId }) == true
            else { return }
            showBurst(combo)
        case nil:
            return
        }
    }

    /// 손목을 내려 화면이 어두워지거나 꺼지면 띄우던 순간도 지운다.
    func onScreenActiveChanged(_ isActive: Bool) {
        isScreenActive = isActive
        if !isActive {
            smallMoments.removeAll()
            burst = nil
        }
    }

    func onControlsShownChanged(_ isShown: Bool) {
        isControlsShown = isShown
    }

    // 넘겨 둔 장이 돌아와 늦게 그려져도 지난 순간을 틀지 않게 시간이 지나면 지운다
    private func showSmall(_ combo: WatchComboTriggered) {
        let moment = ComboMoment(eventId: combo.eventId, startedAt: now())
        smallMoments[combo.userId] = moment
        _ = schedule(ComboMoment.smallDuration) { [weak self] in
            guard let self, smallMoments[combo.userId] == moment else { return }
            smallMoments[combo.userId] = nil
        }
    }

    // 다 그릴 때까지 다음 큰 순간은 받지 않는다 — 폰도 임팩트 중엔 새로 터뜨리지 않는다
    // 조작 장에선 덮개가 일시정지·종료를 가려 띄우지 않는다
    private func showBurst(_ combo: WatchComboTriggered) {
        guard burst == nil, !isControlsShown else { return }
        let shown = ComboBurst(
            moment: ComboMoment(eventId: combo.eventId, startedAt: now()),
            userId: combo.userId,
            comboCount: combo.comboCount
        )
        burst = shown
        _ = schedule(ComboMoment.bigDuration) { [weak self] in
            guard let self, burst == shown else { return }
            burst = nil
        }
    }
}
