import SwiftUI

/// 러닝 중 화면이다. 첫 화면에서 오른쪽으로 쓸면 조작 장, 왼쪽으로 쓸면 내 기록 장,
/// 위로 쓸거나 크라운을 돌리면 파티원 장이 나온다.
struct RunView: View {
    let run: RunState
    let isPhoneReachable: Bool
    let heartRateBpm: Int?
    let birthday: String?
    let commandState: RunCommandState
    let commands: RunCommands
    /// 사람 번호마다 그릴 사진이다. 없는 사람은 첫 글자로 그린다.
    var playerPhotos: [String: CGImage] = [:]
    /// 사람 번호마다 지금 띄우는 작은 순간이다.
    var smallComboMoments: [String: ComboMoment] = [:]
    /// 지금 화면을 덮는 큰 순간이다.
    var comboBurst: ComboBurst?
    /// 조작 장에선 큰 순간을 띄우지 않아, 조작 장이 보이는지 알린다.
    var onControlsShownChanged: (Bool) -> Void = { _ in }

    @State private var page = RunPage.overview
    @State private var verticalPage = RunVerticalPage.overview
    @State private var arePageDotsShown = true

    @AppStorage(ComboEffectSetting.key) private var isComboEffectOn = ComboEffectSetting.defaultIsOn

    var body: some View {
        TabView(selection: horizontalSelection) {
            ControlsView(
                run: run,
                isPhoneReachable: isPhoneReachable,
                commandState: commandState,
                commands: commands,
                isComboEffectOn: $isComboEffectOn
            )
            .tag(RunPage.controls)
            TabView(selection: $verticalPage) {
                RunOverviewView(
                    run: run,
                    isPhoneReachable: isPhoneReachable,
                    heartRateBpm: heartRateBpm,
                    birthday: birthday,
                    playerPhotos: playerPhotos,
                    smallComboMoments: smallComboMoments
                )
                .tag(RunVerticalPage.overview)
                ForEach(run.players, id: \.userId) { player in
                    PlayerView(
                        run: run,
                        player: player,
                        isPhoneReachable: isPhoneReachable,
                        smallComboMoment: smallComboMoments[player.userId]
                    )
                    .tag(RunVerticalPage.player(userId: player.userId))
                }
            }
            // 기본 전환은 장이 끊겨 화면이 바뀌듯 넘어가, 갤럭시처럼 이어 넘긴다
            .tabViewStyle(.verticalPage(transitionStyle: .identity))
            // 시스템 세로 점은 화면 끝 진행 링 위에 그려져, 끄고 링 안쪽에 직접 그린다
            .scrollIndicators(.hidden)
            .overlay {
                if let dots = VerticalPageDotsContent(players: run.players, verticalPage: verticalPage) {
                    VerticalPageDotsView(content: dots)
                        .opacity(arePageDotsShown ? 1 : 0)
                }
            }
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
        .overlay {
            if let comboBurst, let player = run.players.first(where: { $0.userId == comboBurst.userId }) {
                ComboBurstView(burst: comboBurst, player: player)
            }
        }
        .onChange(of: page, initial: true) { _, page in
            onControlsShownChanged(page == .controls)
        }
        // 세로 점은 잠깐만 보인다 — 갤럭시는 넘기는 동안, 여기는 장이 뜨거나 바뀐 뒤다
        // 첫 화면으로 돌아오거나 파티원 장이 생길 때도 다시 보여야 해서 셋을 같이 본다
        .task(id: PageDotsTrigger(page: page, verticalPage: verticalPage, playerCount: run.players.count)) {
            arePageDotsShown = true
            try? await Task.sleep(for: Self.pageDotsHideDelay)
            guard !Task.isCancelled else { return }
            withAnimation { arePageDotsShown = false }
        }
        // 보던 파티원이 명단에서 빠지면 첫 화면으로 돌아온다 — 안 그러면 좌우로 못 넘어간다
        .onChange(of: run.players.map(\.userId)) { _, userIds in
            if case .player(let userId) = verticalPage, !userIds.contains(userId) {
                verticalPage = .overview
            }
        }
    }

    // scrollDisabled로는 TabView 넘기기가 안 막혀 가로 선택을 거절한다
    private var horizontalSelection: Binding<RunPage> {
        Binding(
            get: { page },
            set: { newPage in
                if page.canMoveSideways(verticalPage: verticalPage) { page = newPage }
            }
        )
    }

    private static let pageDotsHideDelay = Duration.seconds(2)
}

/// 가로 장이다. 왼쪽부터 조작 장, 첫 화면 칸, 내 기록 장이다.
enum RunPage {
    case controls
    case overview
    case myRecord

    /// 첫 화면 칸에서 파티원 장을 볼 때만 좌우로 안 넘어간다.
    /// 조작 장·내 기록 장에선 화면 밖 세로 장이 어디 있든 첫 화면으로 돌아갈 수 있어야 한다.
    func canMoveSideways(verticalPage: RunVerticalPage) -> Bool {
        self != .overview || verticalPage == .overview
    }
}

/// 첫 화면 칸의 세로 장이다. 첫 화면 아래로 파티원마다 한 장이 있다.
enum RunVerticalPage: Hashable {
    case overview
    case player(userId: String)
}

/// 세로 장 위치 점이 그릴 값이다.
struct VerticalPageDotsContent: Equatable {
    let count: Int
    let currentIndex: Int

    /// 파티원이 없으면 세로 장이 첫 화면 하나라 nil이다.
    init?(players: [Player], verticalPage: RunVerticalPage) {
        guard !players.isEmpty else { return nil }
        count = players.count + 1
        // 보던 파티원이 명단에서 빠진 사이엔 첫 화면으로 돌아가므로 첫 점을 가리킨다
        if case .player(let userId) = verticalPage,
            let index = players.firstIndex(where: { $0.userId == userId })
        {
            currentIndex = index + 1
        } else {
            currentIndex = 0
        }
    }
}

private struct PageDotsTrigger: Hashable {
    let page: RunPage
    let verticalPage: RunVerticalPage
    let playerCount: Int
}

/// 세로 장 위치 점이다. 링 안쪽 오른쪽 끝, 화면 세로 가운데에 둔다.
private struct VerticalPageDotsView: View {
    let content: VerticalPageDotsContent

    var body: some View {
        ScreenLayoutView { screen in
            VStack(spacing: Self.dotSpacing - Self.dotDiameter) {
                ForEach(0..<content.count, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(index == content.currentIndex ? 1 : Self.inactiveDotAlpha))
                        .frame(width: Self.dotDiameter, height: Self.dotDiameter)
                }
            }
            // 점도 글자처럼 링 안쪽 여백 안에 둔다
            .position(
                x: screen.screenWidth - RunDimensions.textEdgeMargin - Self.dotDiameter / 2,
                y: screen.screenHeight / 2
            )
        }
        .allowsHitTesting(false)
    }

    private static let dotDiameter: CGFloat = 3
    private static let dotSpacing: CGFloat = 6
    private static let inactiveDotAlpha = 0.35
}

#Preview("러닝 화면 파티") {
    RunView(
        run: RunSamples.party,
        isPhoneReachable: true,
        heartRateBpm: 148,
        birthday: RunSamples.birthday,
        commandState: RunCommandState(),
        commands: RunCommands(pause: {}, resume: {}, finish: {})
    )
}
