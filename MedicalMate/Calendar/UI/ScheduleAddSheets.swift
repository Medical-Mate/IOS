import SwiftUI

/// `1r-4`의 시트 셋 — 날짜(`1r-4-D` `3663:14950`) · 시간(`1r-4-T` `3663:15087`) ·
/// 예약 문자 안내(`3663:14855`).
///
/// 화면 본문과 떼어 둔다. 한 타입에 다 두면 길이 상한을 넘고, Android도
/// `ScheduleAddSheets.kt`로 떼어 두었다.
extension ScheduleAddView {
    /// 시안 `1r-4-D`(`3663:14950`)의 칸이 **14 · 10 · 12**다. 한 값(16)으로 두고
    /// 있었다. 월 머리도 시안이 **32**인데(`3663:14955`) 아이콘 단추가 `.l`(48)이라
    /// 그만큼 높았다. Android `DateSheet`도 `s10` · `s12` · `IconButtonSize.S`다.
    func dateSheet(_ model: ScheduleAddModel) -> some View {
        MMBottomSheet {
            VStack(spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                Text("날짜 선택")
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)

                Color.clear.frame(height: MMSpace.s10)

                HStack(spacing: MMSpace.s8) {
                    MMIconButton(icon: .chevronLeft, label: "지난달", size: .s) {
                        model.sheetGoToPreviousMonth()
                    }
                    Text(model.sheetMonth.title)
                        .mmTextStyle(MMFont.bodyLStrong)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity)
                    MMIconButton(icon: .chevronRight, label: "다음달", size: .s) {
                        model.sheetGoToNextMonth()
                    }
                }

                // 시트의 그리드는 범례를 끄고 **그림자도 뺀다.** 고르는 자리라 보여 줄
                // 상태가 없고, 시트가 이미 떠 있어 그 위에 또 띄우면 면이 둘로 읽힌다.
                MMCalendarGrid(
                    days: model.sheetDays,
                    showsLegend: false,
                    isElevated: false
                ) { model.sheetSelect(day: $0) }

                Color.clear.frame(height: MMSpace.s12)

                MMButton("확인") { model.confirmDate() }
            }
        }
    }

    func timeSheet(_ model: ScheduleAddModel) -> some View {
        @Bindable var model = model

        // 시안 `1r-4-T`(`3663:15087`)의 칸이 **14 · 12 · 10**이다. 여기도 16 하나로
        // 두고 있었다. Android는 시트 기본값(12)이라 마지막 칸이 2 다르다 — 시안을
        // 따른다.
        return MMBottomSheet {
            VStack(spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                Text("시간 선택")
                    .mmTextStyle(MMFont.headingS)
                    .foregroundStyle(MMColor.fgDefault)

                Color.clear.frame(height: MMSpace.s12)

                MMTimeWheel(
                    isMorning: $model.sheetIsMorning,
                    hour: $model.sheetHour,
                    minute: $model.sheetMinute
                )

                Color.clear.frame(height: MMSpace.s10)

                MMButton("확인") { model.confirmTime() }
            }
        }
    }

    /// `1r-4-S` 예약 문자 방법 안내 (Figma `3663:14855`).
    ///
    /// **가져오기 자체는 Share Extension이 필요해 M4다.** 지금은 방법만 알린다.
    func shareGuideSheet(_ model: ScheduleAddModel) -> some View {
        MMBottomSheet {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear.frame(height: MMSpace.s14)

                VStack(alignment: .leading, spacing: MMSpace.s4) {
                    Text("예약 문자로 일정 채우기")
                        .mmTextStyle(MMFont.headingM)
                        .foregroundStyle(MMColor.fgDefault)
                    Text("병원에서 받은 문자를 공유하면 돼요.")
                        .mmTextStyle(MMFont.bodyM)
                        .foregroundStyle(MMColor.fgSubtle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Color.clear.frame(height: MMSpace.s16)

                MMIllustration.shareSheet.view()
                    .frame(maxWidth: .infinity)

                Color.clear.frame(height: MMSpace.s16)

                VStack(alignment: .leading, spacing: MMSpace.s12) {
                    MMStepRow(number: 1, text: "문자 앱에서 예약 문자를 길게 눌러요")
                    MMStepRow(number: 2, text: "공유를 누르고 진료메이트를 골라요")
                    MMStepRow(number: 3, text: "채워진 병원, 날짜, 시간을 확인하고 저장해요")
                    MMStepRow(number: 4, text: "진료메이트가 안 보이면 더보기에서 찾아주세요")
                }
            }
        }
    }
}
