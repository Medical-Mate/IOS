import SwiftUI

/// 디자인 시스템 `Card Thumbnail / Long Image` (Figma `3610:10202`).
///
/// Figma 설명 그대로: **카드를 이미지로 내보내기 시트(1e-1-X) 미리보기 안 축소 카드
/// 160×250. 긴 이미지 한 장의 모양을 보여 준다.**
///
/// 안쪽 줄은 글이 아니라 **모양만 보여 주는 막대**다. 내보낼 카드의 실제 내용이 아니라
/// "한 장으로 길게 나온다"를 알리는 그림이라 마스터의 막대 폭을 그대로 옮긴다.
struct MMCardThumbnail: View {
    var title: String = "복부 통증 · 3주"
    var meta: String = "김OO · OO세 여 · 2026.09.18 작성"

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s4) {
            Text(title)
                .font(.pretendard(.bold, size: ThumbnailMetrics.titleSize))
                .foregroundStyle(MMColor.fgDefault)
            Text(meta)
                .font(.pretendard(.regular, size: ThumbnailMetrics.metaSize))
                .foregroundStyle(MMColor.fgMuted)

            ForEach(Array(ThumbnailMetrics.blocks.enumerated()), id: \.offset) { _, block in
                RoundedRectangle(cornerRadius: block.radius)
                    .fill(block.color)
                    .frame(width: block.width, height: block.height)
            }
        }
        .padding(ThumbnailMetrics.padding)
        .frame(width: ThumbnailMetrics.width, height: ThumbnailMetrics.height, alignment: .topLeading)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: ThumbnailMetrics.radius))
        .mmShadow(MMElevation.card)
        .accessibilityLabel("브리핑 카드 미리보기")
    }
}

private enum ThumbnailMetrics {
    static let width: CGFloat = 160
    static let height: CGFloat = 250
    static let padding: CGFloat = 7
    static let radius: CGFloat = 8.136
    static let titleSize: CGFloat = 9.492
    static let metaSize: CGFloat = 8.136

    struct Block {
        let width: CGFloat
        let height: CGFloat
        let radius: CGFloat
        let color: Color
    }

    /// 마스터의 막대 그대로. 본문 줄은 `bg/subtle`, 강조 블록은 amber·primary 면이다.
    static let blocks: [Block] = [
        .init(width: 131.525, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 103.051, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 116.61, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 88.136, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 73.22, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 146.441, height: 21.695, radius: 7.232, color: MMColor.bgWarning),
        .init(width: 88.136, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 124.746, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 109.831, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 146.441, height: 59.661, radius: 10.847, color: MMColor.bgPrimaryFaint),
        .init(width: 73.22, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 116.61, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
        .init(width: 146.441, height: 28.475, radius: 9.492, color: MMColor.bgSubtle),
        .init(width: 66.441, height: 4.068, radius: 2.034, color: MMColor.bgSubtle),
    ]
}

/// 디자인 시스템 `Export Preview / Long Image` (Figma `3610:10245`).
///
/// Figma 설명 그대로: **카드를 이미지로 내보내기 시트(1e-1-X) 미리보기 영역 320×300.**
/// `Card Thumbnail` + `Chip Type=Info` "긴 이미지 1장".
struct MMExportPreview: View {
    var chipText: String = "긴 이미지 1장"

    var body: some View {
        ZStack(alignment: .topLeading) {
            MMColor.bgSubtle

            MMCardThumbnail()
                .offset(x: ExportPreviewMetrics.thumbnailX, y: ExportPreviewMetrics.thumbnailY)

            MMInfoChip(text: chipText)
                .offset(x: ExportPreviewMetrics.chipX, y: ExportPreviewMetrics.chipY)
        }
        .frame(width: ExportPreviewMetrics.width, height: ExportPreviewMetrics.height)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.md))
    }
}

private enum ExportPreviewMetrics {
    static let width: CGFloat = 320
    static let height: CGFloat = 300
    static let thumbnailX: CGFloat = 80
    static let thumbnailY: CGFloat = 25
    static let chipX: CGFloat = 228
    static let chipY: CGFloat = 264
}

#Preview {
    MMExportPreview()
        .padding(MMSize.gutter)
        .background(MMColor.bgCanvas)
}
