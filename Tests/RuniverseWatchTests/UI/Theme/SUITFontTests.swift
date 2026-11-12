import Testing
import UIKit

@testable import RuniverseWatch

struct SUITFontTests {

    @Test
    func `글꼴을 처음 쓰면 패키지 번들의 SUIT 굵기 셋이 모두 등록된다`() {
        // when
        _ = SUITFont.font(.semiBold, size: 14)

        // then
        #expect(UIFont(name: "SUIT-Medium", size: 14) != nil)
        #expect(UIFont(name: "SUIT-SemiBold", size: 14) != nil)
        #expect(UIFont(name: "SUIT-Bold", size: 14) != nil)
    }

    @Test
    func `숫자와 꼬리 없는 단위는 숫자 높이로 잰다`() {
        // when & then
        #expect(SUITFont.ink(for: "5'32\"") == SUITFont.numeralInk)
        #expect(SUITFont.ink(for: "km") == SUITFont.numeralInk)
        #expect(SUITFont.ink(for: "kcal") == SUITFont.numeralInk)
    }

    @Test
    func `꼬리 있는 라틴 글자는 기준선 아래 깊이를 더한다`() {
        // when & then
        #expect(SUITFont.ink(for: "bpm") == SUITFont.descenderInk)
        #expect(SUITFont.ink(for: "spm") == SUITFont.descenderInk)
    }

    @Test
    func `한글이 들어 있으면 한글 높이로 잰다`() {
        // when & then
        #expect(SUITFont.ink(for: "폰 연결 확인 중") == SUITFont.hangulInk)
        #expect(SUITFont.ink(for: "멈춤") == SUITFont.hangulInk)
    }

    @Test
    func `한글과 꼬리 글자가 섞이면 위아래 각각 큰 쪽을 쓴다`() {
        // when & then -> 위는 한글, 아래는 p 꼬리를 쓴다
        #expect(SUITFont.ink(for: "심박 bpm") == InkExtent(aboveBaselineEm: 0.814, belowBaselineEm: 0.216))
    }
}
