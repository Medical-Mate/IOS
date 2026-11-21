import Foundation
import Testing
@testable import MedicalMate

/// 1m-B 병원 찾기의 규칙.
struct HospitalPickTests {
    private func result(_ names: [String], total: Int? = nil) -> HospitalSearchResult {
        let hospitals = names.map { Hospital(name: $0, address: "서울 관악구 남부순환로 1820") }
        return HospitalSearchResult(hospitals: hospitals, total: total ?? hospitals.count)
    }

    // MARK: - 응답 옮기기

    @Test("totalCount가 없으면 받은 수로 센다")
    func countsReceivedWhenTotalMissing() {
        let mapped = HospitalRepository.result(from: HospitalSearchResponse(
            hospitals: [HospitalResponse(name: "서울OO병원 내과", address: "서울 관악구")],
            totalCount: nil
        ))
        #expect(mapped.total == 1)
        #expect(!mapped.isTruncated)
    }

    @Test("받은 것보다 전체가 많으면 잘린 것이다")
    func moreTotalMeansTruncated() {
        let found = result(["하나", "둘"], total: 4321)
        #expect(found.isTruncated)
    }

    @Test("같은 이름의 다른 지점은 주소로 갈린다")
    func sameNameSplitsByAddress() {
        let a = Hospital(name: "서울OO병원", address: "서울 관악구 남부순환로 1820, 3층")
        let b = Hospital(name: "서울OO병원", address: "서울 관악구 남부순환로 1820, 4층")
        #expect(a.id != b.id)
    }

    // MARK: - 결과 줄

    @Test("결과 줄은 찾는 중 실패 없음 잘림 개수 순으로 갈린다")
    func resultLabelPrecedence() {
        let found = result(["하나", "둘"])
        #expect(HospitalRepository.resultLabel(isSearching: true, hasFailed: false, result: found) == "찾는 중이에요")
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: true, result: found)
            == "지금은 찾지 못했어요. 잠시 뒤 다시 해주세요.")
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: false, result: .empty) == "검색 결과 없음")
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: false, result: found) == "검색 결과 2곳")
    }

    @Test("받은 것보다 많으면 좁히라고 적는다")
    func asksToNarrowWhenTruncated() {
        // 부분 일치라 "서울"이면 4천 건이 넘는다. 그때 필요한 것은 목록을 더 보는 것이
        // 아니라 검색어를 좁히는 것이다.
        let found = result(["하나", "둘"], total: 4321)
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: false, result: found)
            == "4321곳 중 2곳이에요. 이름을 더 적으면 좁혀져요.")
    }

    // MARK: - 기다리는 동안 먼저 좁히기

    @Test("답을 기다리는 동안 화면에서 먼저 좁힌다")
    func narrowsLocallyWhileWaiting() {
        let found = result(["서울OO병원 내과", "서울OO병원 이비인후과", "OO정형외과의원"])
        let narrowed = HospitalRepository.narrow(found, by: "이비인후과")
        #expect(narrowed.hospitals.map(\.name) == ["서울OO병원 이비인후과"])
        #expect(narrowed.total == 1)
    }

    @Test("좁혀서 하나도 안 남으면 줄이지 않는다")
    func keepsListWhenNarrowingEmpties() {
        // 빈 목록을 잠깐 보이는 것보다 낡은 목록을 두는 편이 덜 혼란스럽다.
        let found = result(["서울OO병원 내과"])
        #expect(HospitalRepository.narrow(found, by: "치과") == found)
    }

    @Test("빈 검색어로는 좁히지 않는다")
    func emptyQueryDoesNotNarrow() {
        let found = result(["하나", "둘"])
        #expect(HospitalRepository.narrow(found, by: "   ") == found)
    }

    @Test("한 번에 받는 수는 20이고 검색은 300밀리초 뒤에 나간다")
    func pageSizeAndDebounce() {
        #expect(HospitalSearch.pageSize == 20)
        #expect(HospitalSearch.debounce == 0.3)
    }
}

/// 화면이 들고 있는 상태.
@MainActor
struct HospitalPickModelTests {
    private func model() -> HospitalPickModel {
        HospitalPickModel(repository: HospitalRepository(client: HospitalStub.client))
    }

    @Test("검색어를 비우면 결과도 비운다")
    func clearingQueryClearsResults() {
        let model = model()
        model.query = "서울"
        model.query = "   "
        #expect(model.result == .empty)
        #expect(!model.isSearching)
        #expect(model.showsEmptyState)
        model.cancel()
    }

    @Test("고른 것을 다시 누르면 푼다")
    func tappingPickedUnpicks() {
        // 진료받을 병원은 건너뛸 수 있다.
        let model = model()
        let hospital = Hospital(name: "서울OO병원 내과", address: nil)
        model.toggle(hospital)
        #expect(model.isPicked(hospital))
        model.toggle(hospital)
        #expect(model.picked == nil)
    }
}

private enum HospitalStub {
    @MainActor static let client = AppEnvironment().client
}
