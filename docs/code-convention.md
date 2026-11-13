# Code Convention

## 기본 원칙

- 포맷팅은 루트 `.editorconfig`와 `.swift-format`을 기준으로 한다.
- 두 파일과 프로젝트 문서에 없는 규칙은 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)를 따르고, 거기에도 없으면 갤럭시워치 앱과 같게 둔다.

## 네이밍

- 타입·프로토콜은 `UpperCamelCase`, 함수·변수·파라미터·상수·enum case는 `lowerCamelCase`, 폴더는 `UpperCamelCase`로 쓰고, 파일 이름은 대표 타입 이름과 같게 쓴다.
- 이름은 동작·역할이 드러나게 짓고, 축약어·의미 없는 이름(`data`, `info`, `temp`)은 피한다.
- 같은 것은 프로젝트 전체에서 한 이름으로 부른다. 새 이름을 짓기 전에 같은 뜻의 이름을 찾아본다.
- 나는 `me`·`my`, 파티원은 `player`, 사람 사이 거리는 `gap`, 화면 여백은 `…Gap`으로 부른다.
- 화면 가로 폭은 `screenWidth`, 세로 높이는 `screenHeight`로 부른다.
- 폰 메시지는 이벤트·필드 이름을 그대로 쓴다(`WATCH_SYNCED` → `WatchSynced`, `forced`).
- 함수는 View 밖에서 거리·시간·페이스 표기 규칙을 구현하면 `format*`, 사건 콜백은 `on*`, 자릿수 채우기 같은 범용 보조 함수는 동작 이름으로 짓는다.
- 상태를 묻는 Boolean은 `is*`·`are*`·`has*`·`can*`, 들어가는지 판단은 `*Fits*`, 동작을 고르는 옵션은 동사(`abbreviateUnits`, `pointsUp`), 성공 여부를 돌려주는 동작 함수는 동작 이름(`pause`, `stop`)으로 짓는다.
- 진행 상태는 대상을 앞에 둔다(`phoneChecking`, `distanceChecking`).
- 상수는 쓰는 타입 안이나 이름 공간용 `enum`에 `static let`으로 둔다(`RunDimensions.centerHeight`).
- 간격 상수는 서로 다른 둘 사이면 `aToBGap`, 같은 것끼리면 `xGap`으로 짓는다. 패딩으로 넣어도 두 항목 사이면 `…Gap`이다.
- 여백 상수는 화면 끝까지 남기는 여유면 `…Margin`, 패딩으로 넣으면 `…Padding`, 그릴 때 안쪽으로 밀면 `…Inset`으로 짓는다.
- 비율 상수는 전체에 대한 몫이면 `…Fraction`(정수 퍼센트면 `…Percent`), 두 값의 비면 `aToBRatio`로 짓는다.
- 그 밖의 상수는 투명도 `…Alpha`, 각도 `…Degrees`, 경계 미만 판정 `…Below`, 개수 `…Count`, 위치 번호 `…Index`, 최소·최대 `min*`·`max*`, 중심 사이 거리 `…Spacing`, 가장 넓은 값을 재는 예시 `widest*`로 짓는다.
- 백틱 테스트 이름은 네이밍 규칙의 예외다.

## 화면

- 화면·페이지는 파일 하나씩 둔다. 그 화면만 쓰는 부품은 같은 파일에 `private`로 둔다.
- 부품 파일 이름은 View 이름과 같다. `Components.swift`·`Utils.swift`는 만들지 않는다.
- View는 `*View`로 끝낸다(`IdleView`, `ControlsView`, `RunSummaryView`). 다만 항목을 가로로 늘어놓는 줄과 눌리는 줄은 `*Row`(여러 줄이면 `*Rows`), 누르는 부품은 `*Button`으로 짓는다. 자리 계산 결과는 `*Slots`, 미리보기는 `#Preview("<대상> <경우>")`로 짓는다.
- 모양 이름은 역할이 다른 부품이 같이 쓰는 치수에만 쓴다(`pillHeight`).
- 보이는 문구는 `Localizable.xcstrings`에 두고 `bundle: .module`로 읽는다. 표기 규칙(거리·격차·심박 구간)은 View 밖 함수로 두고 단위 테스트한다.
- 문자열 키는 `<쓰는 곳>_<내용>`으로 짓는다. 쓰는 곳은 `run`·`controls`·`unit`·`update`·`idle`이다.
- 화면이 그릴 값(문구·흐림·잠금·보일지)은 View 밖 값 타입으로 계산하고, View는 그 값을 그리기만 한다.
- 시안의 치수를 pt로 그대로 쓰고 px로 환산하지 않는다.
- 화면은 `#Preview`와 시뮬레이터로 맞추고, 마지막은 손목 실물로 확인한다.
- 글자나 배치를 바꾸면 46mm·41mm·40mm에서 확인한다. 겹치거나 잘리면 안 된다. 글자 크기 설정은 따르지 않고 고정한다.
- 달리는 중 값이 바뀌는 칸과 줄 자리는 나올 수 있는 값 중 가장 넓은 것으로 잰다. 글꼴 폭을 재서 고른다.

## 물리량 단위

- 값을 담는 프로퍼티·파라미터·지역 변수에는 단위 접미사 `...Meters` / `...Seconds` / `...Ms` / `...SecondsPerKm` / `...Bpm` / `...Spm` / `...Kcal`을 이름 맨 끝에 붙인다(`extraDecimalBelowMeters`). 단위가 곧 이름인 중간값은 그대로 둔다(`km`, `minutes`, `tenthsOfKm`, `maxBpm`).
- 시간 상수는 `Duration`으로 두고(`…Delay`, `…Timeout`, `…Interval`), 숫자가 필요할 때만 `…Ms`로 짓는다.
- 화면 좌표 `CGFloat`는 pt로 보고 접미사를 붙이지 않는다.

## 주석

- 코드만 봐서는 알 수 없는 이유만 적는다. 코드가 하는 일을 다시 설명하지 않는다.
- 시안·측정·계산에서 온 숫자는 상수로 두고, 추정이면 추정이라고 적는다. 그림 좌표처럼 그 자리에서만 쓰는 숫자는 예외다. 재지 않은 사실을 주석에 쓰지 않는다.
- 한 줄로 쓰고, 길어도 두 줄을 넘기지 않는다.
- 어미는 `~다`로 맺고 명사형으로 끝내지 않는다.
- `//` 주석 끝에는 마침표를 붙이지 않고, `///` 문서 주석에는 붙인다.
- 로그 문구는 명사형으로 끝낸다(`폰 메시지 해석 실패`).
- 명세 문서를 절 번호·문서명 모두 인용하지 않는다. 개편되면 낡으므로 자립하는 문장으로 적는다.
- 보류·미완성은 `// TODO: 파티원 목데이터 — 폰 연결을 만들 때 실제 값으로 교체한다`처럼 적는다.

## 테스트

- 새 로직에는 단위 테스트를 작성한다. Swift Testing(`@Test`·`#expect`)으로 쓰고 watchOS 시뮬레이터에서 돌린다.
- 새 화면은 화면이 그릴 값을 단위 테스트하고, 화면 연결·닫기 흐름은 개발용 앱을 띄우는 UI 테스트로 확인한다. UI 테스트는 XCTest로 쓰고 이름은 `test`로 시작하는 영문으로 짓는다.
- 버그를 고칠 땐 실패를 재현하는 테스트를 먼저 추가한다. 글꼴·기기에 달린 결함은 실기기 전후 사진으로 대신한다.
- 테스트는 given-when-then으로 쓰고, 구분 주석을 `// given`, `// when`, `// then`으로 통일한다. 실행과 검증이 한 문장이면 `// when & then`으로 합칠 수 있고, 토큰 뒤에 `-> 설명`으로 의도를 덧붙일 수 있다.
- 테스트 이름은 행위가 드러나게 짓는다.
- 내부 구현보다 외부에서 관찰 가능한 결과를 검증한다.
- 불필요한 테스트 더블과 호출 횟수 검증을 쓰지 않는다.
- 핵심 조건은 본문에 두고, 나머지 반복 준비는 헬퍼로 뺄 수 있다.
- 테스트는 대상 하나에 파일 하나, 폴더는 Sources를 따라간다(`Phone/PhoneLink.swift` → `Phone/PhoneLinkTests.swift`).
- 테스트 더블은 그 파일에 `private`로 두고, 두 테스트 이상이 쓰면 같은 폴더에 `Fake*.swift`로 뺀다. 공용 `TestUtil` 폴더는 만들지 않는다.
