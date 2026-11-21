import Foundation
import Observation

/// `1s-2 · 건강 정보 수정`(Figma `3663:15798`)의 상태.
///
/// 복용약 · 기저질환 · 알러지 셋을 한 화면에서 고친다. **고를 수 있는 항목은
/// 신상정보 입력(1b)과 같은 배열을 쓴다** — 두 화면의 목록이 갈리면 1b에서 고른 것이
/// 여기에 없는 일이 생긴다. Android도 같은 판단이다(COMPONENT-MAP 3장 #23).
@MainActor
@Observable
final class HealthEditModel {
    /// 단계별로 고른 것.
    private(set) var picked: [Set<String>] = [[], [], []]
    /// 목록에 없지만 이미 저장돼 있던 것. **지우지 않고 칩으로 세운다.**
    private(set) var extras: [[String]] = [[], [], []]
    /// "직접 추가"를 누른 갈래. 없으면 `nil`이다.
    var adding: Int?
    var draft = ""

    private(set) var isLoading = true
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private var base = HealthProfile()
    private let repository: HealthProfileRepository

    init(repository: HealthProfileRepository) {
        self.repository = repository
    }

    var canAddDraft: Bool { !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func load() async {
        if case .success(let profile) = await repository.profile() {
            base = profile
            let fields = [
                profile.health.medications,
                profile.health.conditions,
                profile.health.allergies
            ]
            for (index, field) in fields.enumerated() {
                picked[index] = Set(field.items)
                extras[index] = HealthEditModel.extras(field.items, step: index)
            }
        }
        isLoading = false
    }

    /// 한 갈래에 세울 칩. **고를 수 있는 것 뒤에 직접 적어 둔 것이 붙는다.**
    func options(_ step: Int) -> [String] {
        ProfileSetupStep.all[step].options + extras[step]
    }

    func isPicked(_ step: Int, _ item: String) -> Bool { picked[step].contains(item) }

    func toggle(_ step: Int, _ item: String) {
        if picked[step].contains(item) {
            picked[step].remove(item)
        } else {
            picked[step].insert(item)
        }
    }

    /// "+ 직접 추가"를 눌렀다.
    ///
    /// **이미 열려 있던 갈래를 다시 누르면 닫는다** — 열어 둔 것을 닫을 길이 없으면
    /// 적다 만 입력 칸이 화면에 남는다.
    func startAdding(_ step: Int) {
        adding = adding == step ? nil : step
        draft = ""
    }

    /// 직접 적은 것을 칩으로 세우고 **넣는 동시에 고른 것으로 표시한다** — 적어 넣고
    /// 다시 눌러야 골라지는 것은 한 번에 두 번 시키는 일이다.
    ///
    /// **빈 값과 이미 있는 항목은 넣지 않는다.** 같은 칩이 두 개 생기면 어느 쪽이
    /// 골라졌는지 알 수 없다. 이미 있으면 적던 글만 비우고 칸은 열어 둔다.
    func commitDraft() {
        guard let step = adding else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if options(step).contains(text) {
            draft = ""
            return
        }
        extras[step].append(text)
        picked[step].insert(text)
        draft = ""
        adding = nil
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }

        var profile = base
        profile.health.medications = HealthEditModel.field(picked[0], step: 0, extras: extras[0])
        profile.health.conditions = HealthEditModel.field(picked[1], step: 1, extras: extras[1])
        profile.health.allergies = HealthEditModel.field(picked[2], step: 2, extras: extras[2])

        switch await repository.save(profile) {
        case .success(let saved):
            base = saved
            errorMessage = nil
            return true
        case .rejected, .networkUnavailable:
            errorMessage = "저장하지 못했어요. 잠시 뒤 다시 시도해주세요."
            return false
        }
    }

    // MARK: - 값 옮기기

    /// 목록에 없는 것만 고른다. 이미 저장된 "한약"처럼 1b에서 적은 글이다.
    nonisolated static func extras(_ items: [String], step: Int) -> [String] {
        let options = Set(ProfileSetupStep.all[step].options)
        return items.filter { !options.contains($0) }
    }

    /// **고른 차례가 아니라 보이는 차례로 보낸다.** `Set`은 순서가 없어 저장할 때마다
    /// 줄이 섞이면 카드의 항목 차례도 흔들린다.
    nonisolated static func field(_ picked: Set<String>, step: Int, extras: [String]) -> HealthField {
        let ordered = (ProfileSetupStep.all[step].options + extras).filter { picked.contains($0) }
        // 아무것도 고르지 않은 것을 "없다"로 보지 않는다 — `HealthField`가 `unknown`으로 둔다.
        return HealthField(items: ordered)
    }
}
