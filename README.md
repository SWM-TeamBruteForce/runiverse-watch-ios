# Runiverse Watch iOS

> 멀리 떨어져 있어도 함께 달리는 원격 동반 러닝 플랫폼, **Runiverse**의 애플워치 앱입니다.

폰 앱은 [runiverse-frontend](https://github.com/SWM-TeamBruteForce/runiverse-frontend), 서버는 [runiverse-backend](https://github.com/SWM-TeamBruteForce/runiverse-backend)입니다.
갤럭시워치 앱은 [runiverse-watch-android](https://github.com/SWM-TeamBruteForce/runiverse-watch-android)입니다.

## 기술 스택

| 분류 | 사용 기술 |
|---|---|
| Language / UI | Swift, SwiftUI (watchOS) |
| 코드 제공 방식 | Swift Package |
| 폰 연동 | WatchConnectivity |

## 구성

워치 화면과 로직은 이 레포에 Swift Package로 둘 예정입니다.
폰 앱 레포의 `ios/`에는 워치 앱 타깃과 폰 쪽 연동 코드를 두고, 이 패키지를 SPM으로 연결합니다.

- 워치 앱은 iOS 앱 안에 담겨 함께 출시됩니다. 워치만 고쳐도 iOS 앱을 새로 냅니다.
- 앱 버전과 빌드 번호는 iOS 앱을 따릅니다. 이 레포의 태그는 패키지 버전입니다.

## 개발

- **워치만 볼 때**: 이 레포의 개발용 watchOS 앱 타깃으로 시뮬레이터에서 실행합니다. 패키지만으로는 앱을 실행할 수 없습니다.
- **폰과 같이 볼 때**: 폰 앱 레포에 원격 패키지가 연결된 상태에서, `ios/Runner.xcworkspace`에 이 레포를 로컬 패키지로 추가해 덮어씁니다.
- **반영**: `main`의 검증된 커밋에 태그를 붙이고, 폰 앱 레포에서 그 버전으로 고정합니다. `Package.resolved`도 커밋합니다. 한 번 쓴 태그는 옮기거나 다시 쓰지 않습니다.

- **PR**: 기능 PR은 `dev`로, 릴리스 PR은 `main`으로 올립니다. GitHub 기본 대상이 `main`이니 확인합니다.

## 상태

준비 중입니다. 이 문서는 폰 연동 구성을 기준으로 합니다. 폰 없이 쓸 기능 범위는 아직 정하지 않았습니다.
