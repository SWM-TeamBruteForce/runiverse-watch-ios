# CLAUDE.md

Runiverse 애플워치(watchOS) 앱의 화면·로직을 담은 Swift Package. 폰 앱(runiverse-frontend) `ios/`의 워치 앱 타깃이 SPM으로 가져다 쓴다. 폰 앱과 WatchConnectivity로 붙어, 폰이 기록·판단하고 워치는 표시·입력만 한다.

## 빌드

```bash
xcodebuild build -scheme RuniverseWatch -destination 'generic/platform=watchOS Simulator'   # 패키지 빌드
xcodebuild test -scheme RuniverseWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)'                # 단위 테스트
swift format lint --strict --recursive Package.swift Sources Tests DevApp                    # lint
xcodebuild build -project DevApp/RuniverseWatchDev.xcodeproj -scheme RuniverseWatchDev \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)'                # 개발용 앱 빌드
xcodebuild test -project DevApp/RuniverseWatchDev.xcodeproj -scheme RuniverseWatchDev -parallel-testing-enabled NO \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)'                # UI 테스트
```

## 문서 인덱스 — 구현 전 해당 문서를 읽을 것

- `docs/code-convention.md` — 네이밍·화면·물리량 단위·주석·테스트 규칙
- `docs/git-convention.md` — 커밋·브랜치·PR 규칙
- `docs/phone-communication.md` — 폰↔워치 메시지·번호·상태 모양·보내고 받는 규칙

## 구조

- 라이브러리 타깃은 `RuniverseWatch` 하나, 코드는 `Sources/RuniverseWatch/`. 폴더는 아래 자리에 두고 코드가 생길 때 만든다. 자리를 새로 만들면 여기에 적는다.
  ```
  RuniverseWatchScene         앱 타깃이 띄우는 화면 전체
  RuniverseWatchAppDelegate   폰이 켠 운동·앱이 죽기 전 남은 운동을 받는다. 밖에 공개하는 타입은 이 둘뿐이다
  RootScreen                  폰 상태로 띄울 화면을 고른다
  IdleView                    러닝이 없을 때 화면
  UpdateRequiredView          폰이 워치 버전을 거절했을 때 화면
  Phone/          폰과 메시지 주고받기·연결 상태
  Workout/        러닝 중 앱을 살려 두는 운동 세션·심박 측정
  Run/            러닝 화면·장·결과 요약
  Run/Common/     장 밖에 두는 규칙·값(표기·자리 계산·폰 명령 등)
  Run/Component/  화면·장이 같이 쓰는 UI 부품·치수
  UI/Theme/       여러 기능이 같이 쓰는 색·글자
  UI/Component/   두 기능 이상이 쓰는 부품
  Resources/      문구·글꼴·그림
  ```
- `Run/`에는 화면 파일만 둔다. 장 전용 파일이 둘 이상이면 장 폴더를 만들고, 참조는 `Run/ → Common/ → Component/` 한 방향으로만 한다.
- 단위 테스트는 `Tests/RuniverseWatchTests/`에 Sources와 같은 폴더로, UI 테스트는 개발용 앱 프로젝트의 UI 테스트 타깃에 둔다.
- 화면은 폰 상태로 `switch` 분기한다. 폰 상태는 맨 위 화면 한 곳에서만 읽고, 아래로는 값과 동작 함수만 넘긴다.
- `DevApp/`은 워치만 시뮬레이터로 볼 때 쓰는 개발용 앱이다. 출시되는 앱 타깃은 폰 앱 레포 `ios/`에 있고, 진입점과 앱 타깃에만 둘 수 있는 것(권한·Info.plist·아이콘)만 둔다. 러닝 화면은 실행 인자 `-fakeRun <경우>`로 가짜 폰을 켜서 본다(`Phone/FakePhone.swift`, DEBUG 빌드만).
- `swift-tools-version`은 폰 앱 배포 CI의 Xcode가 읽는 버전까지만 올린다.

## 범위

- 1차는 폰 경유 러닝 화면과 끝난 직후 결과 요약뿐이다. 워치가 서버를 직접 부르는 기능(매칭·기록 보기)은 넣지 않는다.
- 심박은 워치가 재서 워치에만 보여 준다. 폰·서버에 보내지 않는다. 운동 세션 동안 기기의 건강 앱에는 저장된다.

## 주의사항

- 워치 앱은 iOS 앱에 담겨 출시된다. 앱 버전·빌드 번호는 iOS 앱을 따른다. 이 레포의 태그는 패키지 버전이고, 번호는 그 코드가 처음 실리는 iOS 앱 버전으로 붙인다(`v` 없이). 태그 뒤 출시 전에 워치 코드를 고치면 iOS 앱 버전을 올린다. 한 번 쓴 태그는 옮기거나 다시 쓰지 않는다.
- 폰과 주고받는 메시지를 바꿀 땐 두 워치 레포의 통신 문서를 같이 고치고, 폰·갤럭시·애플을 함께 바꾼다.
- 운동 세션·진동·손목 동작은 시뮬레이터로 확인되지 않는다. 실기기로 본다.
- 요청 없이 라이브러리를 추가하지 않는다.
- 문제를 우회하는 해결 금지 — 테스트 약화·빈 catch·기능 삭제로 오류를 없애지 않는다.
