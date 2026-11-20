import Foundation

/// 병원 찾기.
///
/// 원천이 심평원 병원정보서비스이고 **서버가 목록을 들고 있지 않다.** 개원·폐원이 계속
/// 생기는 데이터라 복사해 두면 바로 낡는다는 것이 서버 쪽 설명이다. 그래서 앱도 오래
/// 캐시하지 않는다 — 화면이 떠 있는 동안만 들고 있다가 버린다.
///
/// **부분 일치다.** "서울"로 4천 건이 넘게 나온다.
struct HospitalRepository: Sendable {
    let client: ApiClient

    /// 이름으로 찾는다.
    ///
    /// **빈 검색어로는 부르지 않는다.** 서버가 `q`를 필수로 두고, 그 전에 부분 일치라
    /// 무엇이든 받으면 수천 건이 온다.
    func search(_ query: String) async -> ApiResult<HospitalSearchResult> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .success(.empty) }

        let request = HTTPRequest.get(
            "api/hospitals",
            query: ["q": trimmed, "size": String(HospitalSearch.pageSize)]
        )
        let result = await client.send(request, as: HospitalSearchResponse.self)
        return result.map(Self.result(from:))
    }

    static func result(from response: HospitalSearchResponse) -> HospitalSearchResult {
        let hospitals = (response.hospitals ?? []).map { Hospital(name: $0.name, address: $0.address) }
        return HospitalSearchResult(hospitals: hospitals, total: response.totalCount ?? hospitals.count)
    }

    /// 검색어 줄 아래에 서는 말.
    ///
    /// **받은 것보다 많으면 그 사실을 적는다.** 부분 일치라 "서울"이면 4천 건이 넘는데,
    /// 그때 필요한 것은 목록을 더 보는 것이 아니라 검색어를 좁히는 것이다.
    static func resultLabel(
        isSearching: Bool,
        hasFailed: Bool,
        result: HospitalSearchResult
    ) -> String {
        if isSearching { return "찾는 중이에요" }
        if hasFailed { return "지금은 찾지 못했어요. 잠시 뒤 다시 해주세요." }
        if result.hospitals.isEmpty { return "검색 결과 없음" }
        if result.isTruncated {
            return "\(result.total)곳 중 \(result.hospitals.count)곳이에요. 이름을 더 적으면 좁혀져요."
        }
        return "검색 결과 \(result.hospitals.count)곳"
    }

    /// 답을 기다리는 동안 **화면에서 먼저 좁힌다.**
    ///
    /// 기기에서 재 보니 왕복이 1.3~3.3초다(Android 측정, 중앙값 1.6초). 그동안 목록이
    /// 그대로 있으면 친 글자가 아무 일도 안 하는 것처럼 보인다. 서버 규칙이 이름 부분
    /// 일치라 앱에서도 같은 규칙으로 먼저 줄일 수 있고, 답이 오면 그것으로 바뀐다.
    ///
    /// 줄였더니 하나도 안 남으면 **줄이지 않는다** — 빈 목록을 잠깐 보이는 것보다 낡은
    /// 목록을 두는 편이 덜 혼란스럽다.
    static func narrow(_ result: HospitalSearchResult, by keyword: String) -> HospitalSearchResult {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return result }
        let narrowed = result.hospitals.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        guard !narrowed.isEmpty else { return result }
        return HospitalSearchResult(hospitals: narrowed, total: narrowed.count)
    }
}

/// 병원 찾기의 숫자. Android와 같은 값이다.
enum HospitalSearch {
    /// 한 번에 받는 수.
    ///
    /// 고르는 화면이라 훑을 수 있는 만큼만 받는다. 부분 일치라 "서울"이면 4천 건이
    /// 넘는데, 그때 필요한 것은 더 받는 것이 아니라 **검색어를 좁히는 것**이다.
    static let pageSize = 20

    /// 검색어가 멎고 이만큼 지나면 부른다.
    ///
    /// **한 글자마다 부르면 심평원까지 왕복이 그만큼 간다.** 부위 검색은 앱 안에서
    /// 끝나서 그냥 돌렸지만 이쪽은 다르다.
    static let debounce: Double = 0.3
}
