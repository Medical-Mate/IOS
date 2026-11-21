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

    @Test func totalCount가_없으면_받은_수로_센다() {
        let mapped = HospitalRepository.result(from: HospitalSearchResponse(
            hospitals: [HospitalResponse(name: "서울OO병원 내과", address: "서울 관악구")],
            totalCount: nil
        ))
        #expect(mapped.total == 1)
        #expect(!mapped.isTruncated)
    }

    @Test func 받은_것보다_전체가_많으면_잘린_것이다() {
        let found = result(["하나", "둘"], total: 4321)
        #expect(found.isTruncated)
    }

    @Test func 같은_이름의_다른_지점은_주소로_갈린다() {
        let a = Hospital(name: "서울OO병원", address: "서울 관악구 남부순환로 1820, 3층")
        let b = Hospital(name: "서울OO병원", address: "서울 관악구 남부순환로 1820, 4층")
        #expect(a.id != b.id)
    }

    // MARK: - 결과 줄

    @Test func 결과_줄은_찾는_중_실패_없음_잘림_개수_순으로_갈린다() {
        let found = result(["하나", "둘"])
        #expect(HospitalRepository.resultLabel(isSearching: true, hasFailed: false, result: found) == "찾는 중이에요")
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: true, result: found)
            == "지금은 찾지 못했어요. 잠시 뒤 다시 해주세요.")
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: false, result: .empty) == "검색 결과 없음")
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: false, result: found) == "검색 결과 2곳")
    }

    @Test func 받은_것보다_많으면_좁히라고_적는다() {
        // 부분 일치라 "서울"이면 4천 건이 넘는다. 그때 필요한 것은 목록을 더 보는 것이
        // 아니라 검색어를 좁히는 것이다.
        let found = result(["하나", "둘"], total: 4321)
        #expect(HospitalRepository.resultLabel(isSearching: false, hasFailed: false, result: found)
            == "4321곳 중 2곳이에요. 이름을 더 적으면 좁혀져요.")
    }

    // MARK: - 기다리는 동안 먼저 좁히기

    @Test func 답을_기다리는_동안_화면에서_먼저_좁힌다() {
        let found = result(["서울OO병원 내과", "서울OO병원 이비인후과", "OO정형외과의원"])
        let narrowed = HospitalRepository.narrow(found, by: "이비인후과")
        #expect(narrowed.hospitals.map(\.name) == ["서울OO병원 이비인후과"])
        #expect(narrowed.total == 1)
    }

    @Test func 좁혀서_하나도_안_남으면_줄이지_않는다() {
        // 빈 목록을 잠깐 보이는 것보다 낡은 목록을 두는 편이 덜 혼란스럽다.
        let found = result(["서울OO병원 내과"])
        #expect(HospitalRepository.narrow(found, by: "치과") == found)
    }

    @Test func 빈_검색어로는_좁히지_않는다() {
        let found = result(["하나", "둘"])
        #expect(HospitalRepository.narrow(found, by: "   ") == found)
    }

    @Test func 한_번에_받는_수는_20이고_검색은_300밀리초_뒤에_나간다() {
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

    @Test func 검색어를_비우면_결과도_비운다() {
        let model = model()
        model.query = "서울"
        model.query = "   "
        #expect(model.result == .empty)
        #expect(!model.isSearching)
        #expect(model.showsEmptyState)
        model.cancel()
    }

    @Test func 고른_것을_다시_누르면_푼다() {
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
