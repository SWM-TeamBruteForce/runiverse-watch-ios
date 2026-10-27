# Runiverse Watch iOS

> 멀리 떨어져 있어도 함께 달리는 원격 동반 러닝 플랫폼, **Runiverse**의 애플워치 앱입니다.

폰 앱은 [runiverse-frontend](https://github.com/SWM-TeamBruteForce/runiverse-frontend), 서버는 [runiverse-backend](https://github.com/SWM-TeamBruteForce/runiverse-backend)입니다.
갤럭시워치 앱은 [runiverse-watch-android](https://github.com/SWM-TeamBruteForce/runiverse-watch-android)입니다.

## 기술 스택

| 분류 | 사용 기술 |
|---|---|
| Language / UI | Swift, SwiftUI (watchOS) |
| 배포 단위 | Swift Package |
| 폰 연동 | WatchConnectivity |

## 구성

워치 화면과 로직은 이 레포에 Swift Package로 둡니다.
폰 앱 레포의 `ios/`에는 워치 앱 타깃(진입점·아이콘·entitlements·서명)만 있고, 이 패키지를 SPM으로 가져다 씁니다.

- 워치 앱은 iOS 앱 안에 담겨 함께 출시됩니다. 워치만 고쳐도 iOS 앱을 새로 냅니다.
- 앱 버전은 iOS 앱 버전을 따릅니다. 이 레포의 태그는 패키지 버전입니다.

## 개발

- **워치만 볼 때**: 이 레포에서 워치 시뮬레이터로 실행합니다.
- **폰과 같이 볼 때**: 폰 앱 레포의 `ios/Runner.xcworkspace`를 열고, 이 레포 폴더를 로컬 패키지로 끌어다 놓습니다. 원격 버전 대신 로컬 코드로 빌드됩니다.
- **반영**: 이 레포에 태그를 붙이고, 폰 앱 레포에서 패키지 버전을 그 태그로 올립니다.

## 상태

준비 중입니다. 범위(폰 연동형 / 단독형)는 아직 정하지 않았습니다.
