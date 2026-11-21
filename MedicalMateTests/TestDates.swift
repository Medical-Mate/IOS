import Foundation
@testable import MedicalMate

/// 테스트 픽스처의 날짜.
///
/// **강제 추출을 쓰지 않는다**(SwiftLint `force_unwrapping`). 못 읽으면 아주 오래된 날이
/// 되어 기대값이 바로 깨지므로, 조용히 지나가지 않는다.
func fixtureDay(_ text: String) -> Date {
    HomeRepository.date(from: text) ?? .distantPast
}
