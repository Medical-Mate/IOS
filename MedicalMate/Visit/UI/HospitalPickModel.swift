import Foundation
import Observation

/// `1m-B` 병원 찾기의 상태.
///
/// **검색어가 멎은 뒤에 부른다.** 앞선 요청은 취소한다 — 늦게 온 답이 새 검색어의
/// 결과를 덮으면 화면과 검색어가 어긋난다.
///
/// **한 번 받은 검색어는 다시 부르지 않는다.** 지우고 다시 치는 일이 잦은데 그때마다
/// 1.6초를 기다릴 이유가 없다. 화면을 다시 열면 버린다 — 개원·폐원이 계속 생기는
/// 데이터라 오래 들고 있을 값이 아니다.
@MainActor
@Observable
final class HospitalPickModel {
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            queryChanged()
        }
    }

    private(set) var result: HospitalSearchResult = .empty
    private(set) var isSearching = false
    private(set) var hasFailed = false
    private(set) var picked: Hospital?
    /// 카드를 만드는 중. 두 번 눌리지 않게 막는다.
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let repository: HospitalRepository
    /// 이번 화면에서 받아 둔 결과. 같은 검색어를 다시 치면 그대로 쓴다.
    private var cache: [String: HospitalSearchResult] = [:]
    private var searchTask: Task<Void, Never>?

    init(repository: HospitalRepository) {
        self.repository = repository
    }

    var resultLabel: String {
        HospitalRepository.resultLabel(isSearching: isSearching, hasFailed: hasFailed, result: result)
    }

    /// 빈 자리를 보일지. **검색 전에는 보여줄 것이 없고**, 검색해서 안 나온 경우도
    /// 같은 자리다.
    var showsEmptyState: Bool { result.hospitals.isEmpty }

    func isPicked(_ hospital: Hospital) -> Bool { picked == hospital }

    /// 고른 것을 다시 누르면 푼다 — 진료받을 병원은 건너뛸 수 있다.
    func toggle(_ hospital: Hospital) {
        picked = picked == hospital ? nil : hospital
    }

    func clearQuery() {
        query = ""
    }

    /// 화면을 떠날 때. 돌아다니는 요청을 끊는다.
    func cancel() {
        searchTask?.cancel()
        searchTask = nil
    }

    // MARK: - 안쪽

    private func queryChanged() {
        searchTask?.cancel()
        hasFailed = false

        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            isSearching = false
            result = .empty
            return
        }

        if let cached = cache[keyword] {
            isSearching = false
            result = cached
            return
        }

        // 기다리는 동안 화면에서 먼저 좁힌다. 답이 오면 그것으로 바뀐다.
        result = HospitalRepository.narrow(result, by: keyword)
        isSearching = true

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(HospitalSearch.debounce))
            guard !Task.isCancelled else { return }
            await self?.search(keyword)
        }
    }

    private func search(_ keyword: String) async {
        let outcome = await repository.search(keyword)
        // 돌아온 사이에 검색어가 바뀌었으면 이 답은 버린다.
        guard !Task.isCancelled, keyword == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        isSearching = false
        switch outcome {
        case .success(let found):
            cache[keyword] = found
            result = found
        case .rejected, .networkUnavailable:
            hasFailed = true
        }
    }
}
