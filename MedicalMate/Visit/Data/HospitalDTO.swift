import Foundation

/// `GET /api/hospitals?q=&size=` 한 곳.
struct HospitalResponse: Decodable, Sendable {
    let name: String
    let address: String?
}

/// `totalCount`는 조건에 맞는 **전체** 건수다. 받은 목록보다 클 수 있다.
struct HospitalSearchResponse: Decodable, Sendable {
    let hospitals: [HospitalResponse]?
    let totalCount: Int?
}
