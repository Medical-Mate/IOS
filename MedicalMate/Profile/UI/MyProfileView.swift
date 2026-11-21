import SwiftUI

/// `1s-1 · 내 정보 · 알림 설정` (Figma `3663:15766`).
///
/// 흰 바탕 위에 카드 다섯 장이 선다. 구간 머리 `Section Header`의 보조 액션은
/// **건강 정보에만** 있다("수정").
///
/// 탭이 아니라 홈 헤더의 아바타로 들어오는 화면이다.
struct MyProfileView: View {
    @Environment(\.appEnvironment) private var app
    @State private var model: MyProfileModel?
    @State private var askingWithdraw = false

    var onBack: () -> Void = {}
    var onEditHealth: () -> Void = {}
    var onEditReminderTime: () -> Void = {}
    var onLogout: () -> Void = {}
    var onWithdraw: () -> Void = {}
    var onOpenTerms: () -> Void = {}
    var onOpenPrivacy: () -> Void = {}

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil {
                model = MyProfileModel(health: app.healthProfile, settings: app.settings)
            }
            await model?.load()
        }
    }

    private func content(_ model: MyProfileModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                MMNavBar(title: "내 정보", leading: .back, onLeading: onBack)
                list(model)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(MMColor.bgSurface)

            if askingWithdraw {
                MMOverlayScrim { askingWithdraw = false }
                // 탈퇴는 되돌릴 수 없다. 실수로 한 번 눌러 계정이 사라지면 되돌릴 길이 없다.
                MMDialog(
                    title: "정말 탈퇴하시겠어요?",
                    message: "저장된 브리핑 카드와 진료 기록이 모두 삭제되고 되돌릴 수 없어요",
                    confirmTitle: "탈퇴하기",
                    onCancel: { askingWithdraw = false },
                    onConfirm: {
                        askingWithdraw = false
                        onWithdraw()
                    }
                )
            }
        }
    }

    private func list(_ model: MyProfileModel) -> some View {
        ScrollView {
            // 눈여겨볼 것: 여기서 `VStack`을 쓰면 메이트 줄의 긴 설명이 프로필 카드
            // 아래 빈 띠에 한 번 더 얇게 그려진다(설명이 짧으면 사라진다). 구간을
            // 하나씩 세우는 `LazyVStack`에서는 나오지 않는다.
            LazyVStack(alignment: .leading, spacing: MMSpace.s14) {
                profileCard(model)
                healthSection(model)
                reminderSection(model)
                mateSection(model)
                accountSection
                appSection
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.top, MMSpace.s8)
            .padding(.bottom, MMSpace.s16)
        }
    }

    private func profileCard(_ model: MyProfileModel) -> some View {
        HStack(spacing: MMSpace.s14) {
            MMAvatar(initial: MyProfileModel.initial(model.profile.name), size: ProfileMetrics.avatar)

            VStack(alignment: .leading, spacing: ProfileMetrics.copyGap) {
                Text(model.profile.name ?? "")
                    .mmTextStyle(MMFont.headingM)
                    .foregroundStyle(MMColor.fgDefault)
                let birth = MyProfileModel.birthLine(
                    year: model.profile.birthYear,
                    sex: model.profile.sex
                )
                // 값이 없으면 줄을 그리지 않는다.
                if !birth.isEmpty {
                    Text(birth)
                        .mmTextStyle(MMFont.bodyS)
                        .foregroundStyle(MMColor.fgSubtle)
                }
                Text("카카오로 로그인")
                    .mmTextStyle(MMFont.labelS)
                    .foregroundStyle(MMColor.fgSubtle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ProfileMetrics.cardPadding)
        .frame(maxWidth: .infinity)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(MMElevation.card)
    }

    private func healthSection(_ model: MyProfileModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            MMSectionHeader(title: "건강 정보", actionTitle: "수정", onAction: onEditHealth)
            card(padding: MMSpace.s4) {
                MMKVRow(key: "복용약", value: MyProfileModel.summary(model.profile.health.medications))
                MMKVRow(key: "기저질환", value: MyProfileModel.summary(model.profile.health.conditions))
                // 알러지만 강조한다. 처방이 달라지는 값이다.
                MMKVRow(
                    key: "알러지",
                    value: MyProfileModel.summary(model.profile.health.allergies),
                    kind: .emphasis
                )
            }
        }
    }

    private func reminderSection(_ model: MyProfileModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            MMSectionHeader(title: "알림")
            card {
                MMSettingRow(
                    title: "진료 전 알림",
                    kind: .toggle(
                        Binding(
                            get: { model.reminders.beforeVisit },
                            set: { value in Task { await model.setBeforeVisit(value) } }
                        ),
                        description: MyProfileModel.beforeVisitDescription(model.reminders.beforeVisitTime)
                    ),
                    isTitleStrong: true
                )
                MMSettingRow(
                    title: "진료 후 기록 알림",
                    kind: .toggle(
                        Binding(
                            get: { model.reminders.afterVisit },
                            set: { value in Task { await model.setAfterVisit(value) } }
                        ),
                        description: MyProfileModel.afterVisitDescription(model.reminders.afterVisitTime)
                    ),
                    isTitleStrong: true
                )
                MMSettingRow(
                    title: "알림 시간",
                    kind: .navigation(value: model.reminders.beforeVisitTime.value, action: onEditReminderTime)
                )
            }

            if model.isSystemNotificationOff {
                MMNotice(
                    title: "휴대폰 알림이 꺼져 있어요",
                    message: "켜두셔야 진료 전후에 알려드릴 수 있어요.",
                    tone: .warning
                )
            }

            if let message = model.errorMessage {
                Text(message)
                    .mmTextStyle(MMFont.bodyS)
                    .foregroundStyle(MMColor.fgDanger)
            }
        }
    }

    private func mateSection(_ model: MyProfileModel) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            MMSectionHeader(title: "메이트")
            card {
                MMSettingRow(
                    title: "헤이 메이트로 부르기",
                    kind: .toggle(
                        Binding(get: { model.isWakeWordOn }, set: { model.isWakeWordOn = $0 }),
                        description: "앱 사용시 \"헤이 메이트\"를 불러보세요."
                    ),
                    isTitleStrong: true
                )
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            MMSectionHeader(title: "계정")
            card {
                MMSettingRow(title: "로그아웃", kind: .navigation(action: onLogout))
                MMSettingRow(title: "회원탈퇴", kind: .navigation(action: { askingWithdraw = true }))
            }
        }
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: MMSpace.s14) {
            MMSectionHeader(title: "앱 정보")
            card {
                MMSettingRow(title: "이용약관", kind: .navigation(action: onOpenTerms))
                MMSettingRow(title: "개인정보 처리방침", kind: .navigation(action: onOpenPrivacy))
                MMSettingRow(title: "앱 버전", kind: .navigation(value: ProfileMetrics.appVersion, action: {}))
            }
        }
    }

    private func card(
        padding: CGFloat = MMSpace.s6,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ProfileMetrics.cardPadding)
        .padding(.vertical, padding)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(MMElevation.card)
    }
}

private enum ProfileMetrics {
    /// 시안의 프로필 아바타는 56이다. 마스터 기본(44)보다 크다.
    static let avatar: CGFloat = 56
    /// 카드 좌우 여백. 설정 카드와 건강 카드 모두 18이다.
    static let cardPadding: CGFloat = 18
    /// 프로필 세 줄 사이.
    static let copyGap: CGFloat = 3

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}

#Preview {
    MyProfileView()
}
