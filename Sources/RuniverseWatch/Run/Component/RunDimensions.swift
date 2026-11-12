import CoreGraphics

/// 간격은 보이는 글자 사이로 잰다. 부품 하나만 쓰는 크기는 그 부품 파일에 둔다.
enum RunDimensions {
    // 애플 화면은 갤럭시보다 세로 여유가 있어 묶음 사이를 갤럭시 13보다 넓힌다
    static let groupGap: CGFloat = 18
    static let avatarSize: CGFloat = 24.5
    static let comboBorderWidth: CGFloat = 2
    static let avatarToBottomRowGap: CGFloat = 4
}
