import SwiftUI

/// 러닝 중 화면이다. 첫 화면에서 왼쪽으로 쓸면 내 기록 장이 나온다.
struct RunView: View {
    let run: RunState
    let isPhoneReachable: Bool
    let heartRateBpm: Int?
    let birthday: String?

    @State private var page = RunPage.overview

    var body: some View {
        TabView(selection: $page) {
            RunOverviewView(
                run: run,
                isPhoneReachable: isPhoneReachable,
                heartRateBpm: heartRateBpm,
                birthday: birthday
            )
            .tag(RunPage.overview)
            MyRecordView(
                run: run,
                isPhoneReachable: isPhoneReachable,
                heartRateBpm: heartRateBpm,
                birthday: birthday
            )
            .tag(RunPage.myRecord)
        }
        // 갤럭시처럼 가로 장 표시 점은 두지 않는다
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private enum RunPage {
    case overview
    case myRecord
}

#Preview("러닝 화면 파티") {
    RunView(run: RunSamples.party, isPhoneReachable: true, heartRateBpm: 148, birthday: RunSamples.birthday)
}
