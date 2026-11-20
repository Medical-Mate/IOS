import SwiftUI

/// 들어온 컴포넌트를 한 화면에 모아 Figma 마스터와 눈으로 대조하는 자리.
///
/// 화면이 아니다. Android의 `MedicalMateScreenPreviews`와 같은 쓰임이고, 새 컴포넌트를
/// 더할 때마다 여기에도 한 줄 넣는다. 대조는 Figma 마스터를 열어 나란히 본다.
struct MMComponentGallery: View {
    @State private var chipSelected = true
    @State private var agreed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MMSpace.s24) {
                section("Button · 291:670") {
                    MMButton("다음 단계로", kind: .primary) {}
                    MMButton("진료 기록 보기", kind: .tonal) {}
                    MMButton("이전", kind: .outline) {}
                    MMButton("나중에 하기", kind: .ghost) {}
                    MMButton("예약 취소", kind: .danger) {}
                    HStack(spacing: MMSpace.s8) {
                        MMButton("다음 단계로", kind: .primary, size: .m) {}
                        MMButton("다음 단계로", kind: .primary, size: .s) {}
                    }
                    MMButton("비활성", kind: .primary) {}.disabled(true)
                }

                section("Social Login Button · 383:1302") {
                    MMSocialLoginButton(provider: .kakao) {}
                }

                section("Badge · 311:834") {
                    HStack(spacing: MMSpace.s8) {
                        MMBadge(text: "진료 전", tone: .brand)
                        MMBadge(text: "작성중", tone: .neutral)
                        MMBadge(text: "완료", tone: .success)
                    }
                    HStack(spacing: MMSpace.s8) {
                        MMBadge(text: "임시 저장", tone: .warning)
                        MMBadge(text: "응급", tone: .danger)
                    }
                }

                section("Chip · 311:823") {
                    HStack(spacing: MMSpace.s8) {
                        MMChip(text: "두통", isSelected: chipSelected) { chipSelected.toggle() }
                        MMChip(text: "복통") {}
                        MMInfoChip(text: "긴 이미지 1장")
                    }
                }

                section("Card · 293:656") {
                    ForEach([MMCardEmphasis.default, .brand, .quiet], id: \.self) { emphasis in
                        MMCard(emphasis: emphasis) {
                            Text("진료 전 정리")
                                .mmTextStyle(MMFont.labelS)
                                .foregroundStyle(MMColor.fgSubtle)
                            Text("복부 통증 · 3주")
                                .mmTextStyle(MMFont.headingS)
                                .foregroundStyle(MMColor.fgDefault)
                            Text("3주 전 시작 · 최근 악화. 식후 30분 뒤 심해짐.")
                                .mmTextStyle(MMFont.bodyM)
                                .foregroundStyle(MMColor.fgSubtle)
                        }
                    }
                }

                section("Checkbox · 311:851") {
                    MMCheckbox(text: "진료 기록을 병원에 전달하는 것에 동의합니다", isOn: $agreed)
                }
            }
            .padding(.horizontal, MMSize.gutter)
            .padding(.vertical, MMSpace.s24)
        }
        .background(MMColor.bgCanvas)
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: MMSpace.s12) {
            Text(title)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgMuted)
            content()
        }
    }
}

#Preview {
    MMComponentGallery()
}
