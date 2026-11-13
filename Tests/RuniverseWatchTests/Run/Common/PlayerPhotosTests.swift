import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import RuniverseWatch

struct PlayerPhotosTests {

    @Test
    func `JPEG 사진은 그 사람 번호로 풀린다`() throws {
        // given
        let photos = [PlayerPhoto(userId: "u2", jpegBase64: try jpegBase64(width: 4, height: 3))]

        // when
        let images = PlayerPhotos.decode(photos)

        // then
        #expect(Set(images.keys) == ["u2"])
        #expect(images["u2"]?.width == 4)
        #expect(images["u2"]?.height == 3)
    }

    @Test
    func `못 푼 사진은 빼고 나머지만 남긴다`() throws {
        // given
        let photos = [
            PlayerPhoto(userId: "u2", jpegBase64: "A"),
            PlayerPhoto(userId: "u3", jpegBase64: Data("사진 아님".utf8).base64EncodedString()),
            PlayerPhoto(userId: "u4", jpegBase64: try jpegBase64(width: 4, height: 4)),
        ]

        // when
        let images = PlayerPhotos.decode(photos)

        // then
        #expect(Set(images.keys) == ["u4"])
    }

    @Test
    func `한 변이 256보다 큰 사진은 풀지 않고 뺀다`() throws {
        // given
        let photos = [
            PlayerPhoto(userId: "u2", jpegBase64: try jpegBase64(width: 257, height: 10)),
            PlayerPhoto(userId: "u3", jpegBase64: try jpegBase64(width: 10, height: 257)),
            PlayerPhoto(userId: "u4", jpegBase64: try jpegBase64(width: 256, height: 256)),
        ]

        // when
        let images = PlayerPhotos.decode(photos)

        // then
        #expect(Set(images.keys) == ["u4"])
    }

    @Test
    func `사진이 없으면 빈 결과다`() {
        // when & then
        #expect(PlayerPhotos.decode([]).isEmpty)
    }

    private func jpegBase64(width: Int, height: Int) throws -> String {
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        )
        let image = try #require(context.makeImage())
        let jpeg = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(jpeg, UTType.jpeg.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        try #require(CGImageDestinationFinalize(destination))
        return (jpeg as Data).base64EncodedString()
    }
}
