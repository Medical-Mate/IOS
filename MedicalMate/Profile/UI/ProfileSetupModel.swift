import Foundation
import Observation

/// 신상정보 한 단계가 묻는 것.
///
/// 질문·설명·칩 목록은 Figma 와이어프레임 `1b-1`(`3663:6919`) · `1b-2`(`3663:6938`) ·
/// `1b-3`(`3663:6957`)에서 그대로 가져왔다.
struct ProfileSetupStep: Identifiable, Sendable {
    let id: Int
    let question: String
    let description: String
    let options: [String]
    /// 알러지 단계에만 붙는 툴팁. 없으면 `nil`이다.
    let tooltip: String?

    static let all: [ProfileSetupStep] = [
        .init(
            id: 1,
            question: "지금 드시는 약이 있나요?",
            description: "처방약, 영양제, 한약 모두 포함해요. 여러 개 골라도 돼요.",
            options: ["혈압약", "당뇨약", "진통제", "위장약", "영양제", "한약", "피임약", "수면제"],
            tooltip: nil
        ),
        .init(
            id: 2,
            question: "진단받은 병이 있나요?",
            description: "지금 치료 중이거나 꾸준히 관리하는 것을 알려주세요.",
            options: ["고혈압", "당뇨", "고지혈증", "천식", "갑상선", "위염·역류", "관절염", "우울·불안"],
            tooltip: nil
        ),
        .init(
            id: 3,
            question: "알러지가 있나요?",
            description: "약이나 음식에 반응이 있었다면 꼭 알려주세요.",
            options: ["페니실린", "아스피린", "조개·갑각류", "땅콩", "계란", "꽃가루", "먼지·진드기"],
            tooltip: "브리핑 카드 맨 위에 항상 표시돼요"
        )
    ]
}

/// 1b-1 ~ 1b-3 신상정보의 상태.
///
/// 세 단계가 고른 것과 직접 적은 것을 함께 들고 있다가 마지막에 한 번 저장한다.
/// 단계마다 저장하지 않는 이유는 뒤로 가서 고칠 수 있기 때문이다 — 중간 저장은
/// 되돌릴 때 서버와 화면이 갈린다.
@MainActor
@Observable
final class ProfileSetupModel {
    private(set) var index = 0
    /// 단계별로 고른 칩.
    private(set) var picked: [Set<String>] = [[], [], []]
    /// 단계별로 직접 적은 글.
    var typed: [String] = ["", "", ""]

    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let repository: HealthProfileRepository
    /// 카카오에서 온 값. 저장할 때 그대로 되돌려 보내야 해서 들고 있는다.
    private var base = HealthProfile()

    init(repository: HealthProfileRepository) {
        self.repository = repository
    }

    var step: ProfileSetupStep { ProfileSetupStep.all[index] }
    var isLast: Bool { index == ProfileSetupStep.all.count - 1 }
    var total: Int { ProfileSetupStep.all.count }

    func isPicked(_ option: String) -> Bool { picked[index].contains(option) }

    func toggle(_ option: String) {
        if picked[index].contains(option) {
            picked[index].remove(option)
        } else {
            picked[index].insert(option)
        }
    }

    /// 들어와서 한 번. 이미 저장된 값이 있으면 채워 두고, 카카오에서 온 값도 받아 둔다.
    func load() async {
        if case .success(let profile) = await repository.profile() {
            base = profile
            picked = [
                Set(profile.health.medications.items),
                Set(profile.health.conditions.items),
                Set(profile.health.allergies.items)
            ]
        }
    }

    func back() {
        guard index > 0 else { return }
        index -= 1
    }

    /// 다음으로. 마지막이면 저장하고 끝났는지를 돌려준다.
    func next() async -> Bool {
        guard isLast else {
            index += 1
            return false
        }
        return await save()
    }

    private func save() async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil

        var profile = base
        profile.health = HealthEdit(
            medications: field(at: 0),
            conditions: field(at: 1),
            allergies: field(at: 2)
        )

        let result = await repository.save(profile)
        isSaving = false

        switch result {
        case .success:
            return true
        case .rejected(let error):
            errorMessage = error.message ?? "저장하지 못했어요. 잠시 후 다시 시도해주세요."
            return false
        case .networkUnavailable:
            errorMessage = "연결이 끊어졌어요. 잠시 후 다시 시도해주세요."
            return false
        }
    }

    /// 고른 칩과 직접 적은 글을 한 갈래로 합친다.
    ///
    /// 비어 있으면 `UNKNOWN`이다 — "없다"로 단정하지 않는다.
    private func field(at step: Int) -> HealthField {
        var items = ProfileSetupStep.all[step].options.filter { picked[step].contains($0) }
        let written = typed[step].trimmingCharacters(in: .whitespacesAndNewlines)
        if !written.isEmpty, !items.contains(written) {
            items.append(written)
        }
        return HealthField(items: items)
    }
}
