import SwiftUI

/// 디자인 시스템 로고 (Figma `Logo Symbol` `351:1281` · `Logo Lockup` `351:1303`).
///
/// 심볼은 48×48, 로크업(심볼 + 워드마크)은 139×36이다. Figma에서 내보낸 PDF라
/// **손으로 고치지 않는다.** 바뀌면 원본에서 다시 내보낸다.
///
/// `mark`와 `monoLight`는 단색이라 템플릿으로 넣었다 — 쓰는 쪽이 색을 정한다.
/// `gradient` · `flat` · `subtle`은 브랜드 색이 들어 있어 원본 그대로 그린다.
enum MMLogo {
    enum Symbol: String {
        case gradient = "logo-symbol-gradient"
        case flat = "logo-symbol-flat"
        case subtle = "logo-symbol-subtle"
        case mark = "logo-symbol-mark"
        case monoLight = "logo-symbol-mono-light"
    }

    enum Lockup: String {
        case flat = "logo-lockup-flat"
        case mark = "logo-lockup-mark"
        case monoLight = "logo-lockup-mono-light"
    }

    /// 심볼의 원본 크기.
    static let symbolSize: CGFloat = 48
    /// 로크업의 원본 크기.
    static let lockupSize = CGSize(width: 139, height: 36)
}

extension MMLogo.Symbol {
    @MainActor
    func view(size: CGFloat = MMLogo.symbolSize) -> some View {
        Image(rawValue)
            .resizable()
            .renderingMode(isTemplate ? .template : .original)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var isTemplate: Bool { self == .mark || self == .monoLight }
}

extension MMLogo.Lockup {
    /// 높이를 주면 원본 비율로 폭이 따라온다.
    @MainActor
    func view(height: CGFloat = MMLogo.lockupSize.height) -> some View {
        let ratio = MMLogo.lockupSize.width / MMLogo.lockupSize.height
        return Image(rawValue)
            .resizable()
            .renderingMode(isTemplate ? .template : .original)
            .frame(width: height * ratio, height: height)
            .accessibilityLabel("진료메이트")
    }

    private var isTemplate: Bool { self != .flat }
}

#Preview {
    VStack(spacing: MMSpace.s20) {
        HStack(spacing: MMSpace.s16) {
            MMLogo.Symbol.gradient.view()
            MMLogo.Symbol.flat.view()
            MMLogo.Symbol.subtle.view()
            MMLogo.Symbol.mark.view().foregroundStyle(MMColor.fgDefault)
        }
        MMLogo.Lockup.flat.view()
        MMLogo.Lockup.mark.view().foregroundStyle(MMColor.fgPrimary)
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
