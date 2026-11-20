import SwiftUI

/// 디자인 시스템 아이콘 (Figma `Icon set` · `296:4148`).
///
/// Figma 규격: **24×24 격자 · 라이브 20 · 획 1.75 · 라운드 캡/조인.** 획 색이
/// `fg/default`에 묶여 있어 에셋을 **템플릿으로 넣고 색은 쓰는 쪽이 정한다.**
///
/// **에셋 이름을 화면에서 문자열로 쓰지 않는다.** Figma에서 `download_assets`로 받은
/// PDF를 에셋 카탈로그에 넣고(벡터 보존) 여기서만 가리킨다. 이름이 바뀌면 고칠 자리가
/// 하나다. SwiftUI가 SVG를 읽지 못해 PDF로 받는다 — 경로를 손으로 옮겨 그리지 않는다.
///
/// `*Filled`는 탭바의 활성 상태가 쓴다. `export`는 2026-10-15 추가분(`3434:3096`)이다.
enum MMIcon: String, CaseIterable {
    case alertCircle = "icon-alert-circle"
    case alertTriangle = "icon-alert-triangle"
    case arrowRight = "icon-arrow-right"
    case arrowUp = "icon-arrow-up"
    case bell = "icon-bell"
    case bodyPoint = "icon-body-point"
    case calendar = "icon-calendar"
    case calendarFilled = "icon-calendar-filled"
    case camera = "icon-camera"
    case chat = "icon-chat"
    case check = "icon-check"
    case checkCircle = "icon-check-circle"
    case chevronDown = "icon-chevron-down"
    case chevronLeft = "icon-chevron-left"
    case chevronRight = "icon-chevron-right"
    case chevronUp = "icon-chevron-up"
    case clock = "icon-clock"
    case close = "icon-close"
    case copy = "icon-copy"
    case edit = "icon-edit"
    case emptyBox = "icon-empty-box"
    case export = "icon-export"
    case heartPulse = "icon-heart-pulse"
    case home = "icon-home"
    case homeFilled = "icon-home-filled"
    case hospital = "icon-hospital"
    case info = "icon-info"
    case lock = "icon-lock"
    case mic = "icon-mic"
    case micListening = "icon-mic-listening"
    case micOff = "icon-mic-off"
    case minus = "icon-minus"
    case moreHorizontal = "icon-more-horizontal"
    case note = "icon-note"
    case noteFilled = "icon-note-filled"
    case pill = "icon-pill"
    case plus = "icon-plus"
    case search = "icon-search"
    case searchOff = "icon-search-off"
    case share = "icon-share"
    case spinner = "icon-spinner"
    case stethoscope = "icon-stethoscope"
    case trash = "icon-trash"
    case user = "icon-user"
    case userFilled = "icon-user-filled"
    case waveform = "icon-waveform"
    case wifiOff = "icon-wifi-off"

    var image: Image { Image(rawValue).renderingMode(.template) }
}

extension MMIcon {
    /// 아이콘을 주어진 크기로 그린다. 기본값은 `MMSize.iconLg`(24)로 Figma 격자와 같다.
    @MainActor
    func view(size: CGFloat = MMSize.iconLg) -> some View {
        image.resizable().frame(width: size, height: size)
    }
}
