import Photos
import SwiftUI
import UIKit

/// 브리핑 카드를 이미지로 내보내는 자리(`1e-1-X`).
///
/// **저장과 공유가 같은 이미지를 쓴다.** 그려 두고 한쪽은 사진에 넣고 한쪽은 공유
/// 시트에 넘긴다. Android도 같은 비트맵을 둘에 쓴다(`BriefCardSave.kt` ·
/// `shareBriefCard`).
///
/// **사진은 읽지 않고 넣기만 한다**(`addOnly`). 카드에 복용약 · 기저질환 · 알러지가
/// 들어 있어 사진첩 전체를 열어 달라고 할 까닭이 없다. 그래서 Android처럼
/// `진료메이트` 앨범을 따로 만들지는 않는다 — 앨범을 찾으려면 읽기 권한이 필요하고,
/// 그것이 앨범 하나보다 비싸다. CLAUDE.md 0장이 말하는 "규칙은 가져오고 수단은 iOS
/// 것으로 다시 쓴다"의 자리다.
@MainActor
enum BriefCardExport {
    /// 그린 결과.
    enum Outcome: Equatable {
        case saved
        /// 사진에 넣을 수 없었다. 허락이 없거나 쓰지 못했다.
        case failed
    }

    /// 카드를 그린다. **화면 배율 그대로 그린다** — 진료실에서 확대해 보여 줄 수 있어야 한다.
    static func render(_ view: some View, width: CGFloat, scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content:
            view
                .frame(width: width)
                .background(MMColor.bgSurface)
        )
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    /// 사진에 넣는다.
    ///
    /// **`nonisolated`다.** `performChanges`의 블록은 사진 라이브러리의 제 큐에서
    /// 돌아간다. 이 자리가 `@MainActor`에 묶여 있으면 그 블록이 메인 아닌 곳에서
    /// 깨어나고 Swift 6의 격리 검사가 **앱을 그 자리에서 죽인다** — 받아쓰기의
    /// `authorize()`와 똑같은 함정이고, 그것을 고치고 나서 이 코드를 쓰다 또 밟았다.
    /// 여기서는 배우의 상태를 건드리지 않으므로 격리가 필요 없다.
    nonisolated static func save(_ image: UIImage, at moment: Date = Date()) async -> Outcome {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .failed }
        // **PNG로 넣는다.** 글자가 빽빽한 카드라 JPEG으로 넣으면 획 둘레가 번진다
        // — 진료실에서 의사가 읽을 그림이다. `creationRequestForAsset(from:)`은
        // JPEG으로 굳히므로 PNG를 파일로 쓰고 그 파일을 넣는다. Android도 PNG다.
        guard let png = image.pngData() else { return .failed }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(at: moment))
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            try png.write(to: url)
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }
            return .saved
        } catch {
            return .failed
        }
    }

    /// 저장할 때 쓸 이름. **누를 때마다 새 파일이다** — 같은 카드를 두 번 내보내도
    /// 앞의 것을 덮지 않는다. Android와 같은 꼴이다.
    nonisolated static func fileName(at moment: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "브리핑카드_\(formatter.string(from: moment)).png"
    }
}

/// 공유 시트. **UIKit을 감싸는 자리다** — SwiftUI에 같은 것이 없다(CLAUDE.md 2장).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
