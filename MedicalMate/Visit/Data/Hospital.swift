import Foundation

/// 검색 결과 한 곳.
///
/// **주소가 같은 이름을 가르는 유일한 값이다.** 같은 이름의 다른 지점을 구별할 수 있는
/// 것이 주소뿐이라 백엔드에 따로 요청해 홈페이지 자리를 대신했다(Backend#80).
/// 심평원에 없는 곳은 비어 있을 수 있다.
struct Hospital: Sendable, Equatable, Identifiable {
    let name: String
    let address: String?

    /// 이름이 같은 다른 지점이 있어서 주소까지 넣어야 한 줄이 한 곳을 가리킨다.
    var id: String { "\(name)|\(address ?? "")" }
}

/// 찾은 결과.
///
/// `total`은 조건에 맞는 **전체** 건수다. 받은 목록보다 클 수 있고, 그때는 검색어를 더
/// 좁혀야 한다는 뜻이다. **화면이 그것을 알려야** 사용자가 목록 끝까지 훑다 포기하지
/// 않는다.
struct HospitalSearchResult: Sendable, Equatable {
    let hospitals: [Hospital]
    let total: Int

    /// 받은 것보다 더 있는지.
    var isTruncated: Bool { total > hospitals.count }

    static let empty = HospitalSearchResult(hospitals: [], total: 0)
}
