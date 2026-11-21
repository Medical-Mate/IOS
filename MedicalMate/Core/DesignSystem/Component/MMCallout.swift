import SwiftUI

/// 디자인 시스템 `Callout` (Figma `293:657`).
///
/// Figma 설명 그대로:
/// > D5의 최강 블록 — "환자가 묻고 싶어 하는 것". **브리핑 카드에서 한 번만.** 면은
/// > `bg/primary-subtle`(환자의 것), 질문마다 pill을 얹어 **한 항목씩 집어 읽게** 만든다.
/// > 이전 불릿 목록은 세 줄이 한 덩어리로 보여서 진료실에서 짚어가며 말하기 어려웠다.
/// > 번호 칩은 `bg/primary` — 의사에게 "몇 개를 묻고 싶은지"가 먼저 보인다. 헤더 라벨은
/// > `Label/S` + `fg/primary`로 가라앉히고 질문 본문을 `fg/default`로 세운다.
/// > **주인공은 질문이다.**
///
/// 설명은 질문 pill을 "흰 75% 반투명"이라고 적었는데 마스터는 `bg/surface`(불투명)다.
/// 마스터를 따랐다.
struct MMCallout: View {
    let title: String
    let questions: [String]
    /// 편집 중이면 질문마다 지우기가 서고 아래에 "질문 추가"가 붙는다.
    var isEditing: Bool = false
    var onDelete: ((Int) -> Void)?
    var onAdd: (() -> Void)?
    /// 이 번호부터는 **이번에 더한 줄**이라 그 자리에서 적는다(1e-1-A2 `1117:796`).
    /// 마스터의 `Question 4`가 값 대신 밑줄 친 빈 칸이다. 이미 담긴 질문은 고치지 않고
    /// 지웠다 다시 더한다.
    var editableFrom: Int?
    var value: ((Int) -> Binding<String>)?

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s12) {
            header
            VStack(spacing: MMSpace.s8) {
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    row(index: index, text: question)
                }
            }
            if isEditing {
                addRow
            }
        }
        .padding(MMSpace.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MMColor.bgPrimarySubtle)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
    }

    private var header: some View {
        HStack(spacing: MMSpace.s8) {
            MMIcon.chat.view(size: MMSize.iconSm)
                .foregroundStyle(MMColor.fgPrimary)
            Text(title)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(index: Int, text: String) -> some View {
        HStack(spacing: MMSpace.s10) {
            Text("\(index + 1)")
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgOnPrimary)
                .frame(width: CalloutMetrics.num, height: CalloutMetrics.num)
                .background(MMColor.bgPrimary)
                .clipShape(RoundedRectangle(cornerRadius: CalloutMetrics.numRadius))

            if isEditing, let editableFrom, index >= editableFrom, let value {
                VStack(spacing: CalloutMetrics.fieldGap) {
                    TextField("", text: value(index))
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgDefault)
                        .textFieldStyle(.plain)
                    Rectangle()
                        .fill(MMColor.borderSubtle)
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(text)
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isEditing {
                MMIconButton(icon: .close, label: "질문 지우기", style: .ghost, size: .s) {
                    onDelete?(index)
                }
            }
        }
        .padding(.leading, MMSpace.s12)
        .padding(.trailing, MMSpace.s14)
        .padding(.vertical, MMSpace.s12)
        // 질문 pill은 **흰 75% 반투명**이다. 아래 `bg/info` 면이 비쳐 묶음 안의 줄로
        // 읽힌다(COMPONENT-MAP 3장 #8).
        .background(MMColor.bgSurface.opacity(CalloutMetrics.pillOpacity))
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.sm))
    }

    private var addRow: some View {
        Button { onAdd?() } label: {
            HStack(spacing: MMSpace.s8) {
                MMIcon.plus.view(size: MMSize.iconSm)
                Text("질문 추가").mmTextStyle(MMFont.bodyMStrong)
            }
            .foregroundStyle(MMColor.fgPrimary)
            .frame(height: MMSize.controlSm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum CalloutMetrics {
    static let num: CGFloat = MMSize.iconMd
    static let numRadius: CGFloat = 10
    /// 빈 칸의 글자와 밑줄 사이.
    static let fieldGap: CGFloat = 5
    /// 질문 pill의 흰 면 불투명도. Android `Callout.kt`의 `QUESTION_PILL_ALPHA`와 같다.
    static let pillOpacity: Double = 0.75
}

#Preview {
    VStack(spacing: MMSpace.s16) {
        MMCallout(
            title: "환자가 묻고 싶어 하는 것",
            questions: ["검사를 받아야 하나요?", "지금 진통제 계속 먹어도 되나요?", "어떤 증상이면 바로 다시 와야 하나요?"]
        )
        MMCallout(
            title: "환자가 묻고 싶어 하는 것",
            questions: ["검사를 받아야 하나요?"],
            isEditing: true
        )
    }
    .padding(MMSize.gutter)
    .background(MMColor.bgCanvas)
}
