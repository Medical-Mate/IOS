import SwiftUI

/// 화면 위 안전영역 높이.
///
/// Figma 시안에는 상태바가 없어서 화면이 y=0에서 시작한다. 기기에서는 그만큼 내려야
/// 로고와 아이콘이 시계·노치에 겹치지 않는다. 배너처럼 사진이 안전영역까지 올라가되
/// 글자만 내려와야 하는 자리에서 쓴다.
private struct MMSafeAreaTopKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var mmSafeAreaTop: CGFloat {
        get { self[MMSafeAreaTopKey.self] }
        set { self[MMSafeAreaTopKey.self] = newValue }
    }
}
