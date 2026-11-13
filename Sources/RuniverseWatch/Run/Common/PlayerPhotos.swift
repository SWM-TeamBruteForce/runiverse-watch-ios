import CoreGraphics
import Foundation
import ImageIO
import OSLog

/// 폰이 보낸 파티원 사진을 화면에 그릴 수 있게 푼다.
enum PlayerPhotos {
    /// 사람 번호마다 그릴 사진이다. 못 푼 사진은 빼서 그 사람은 첫 글자로 그린다.
    static func decode(_ photos: [PlayerPhoto]) -> [String: CGImage] {
        var images: [String: CGImage] = [:]
        for photo in photos {
            if let image = decodeImage(photo.jpegBase64) {
                images[photo.userId] = image
            } else {
                logger.warning("파티원 사진 풀기 실패 — \(photo.userId, privacy: .public)")
            }
        }
        return images
    }

    private static func decodeImage(_ jpegBase64: String) -> CGImage? {
        guard let data = Data(base64Encoded: jpegBase64),
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int,
            width <= maxPhotoSide, height <= maxPhotoSide
        else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // 폰은 64로 줄여 보낸다 — 원본이 잘못 와도 풀다가 앱이 죽지 않게 넉넉히 막는다
    private static let maxPhotoSide = 256

    private static let logger = Logger(subsystem: "RuniverseWatch", category: "PlayerPhotos")
}
