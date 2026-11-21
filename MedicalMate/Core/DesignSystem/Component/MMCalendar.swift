import SwiftUI

/// 디자인 시스템 `Calendar Day` (Figma `3778:1867`).
///
/// Figma 설명 그대로:
/// > 캘린더 날짜 한 칸 44×46(그리드에서는 폭 Fill). 안쪽 면 42×42 · 반경 13.
/// > **숫자 위치는 점이 있든 없든 고정(위 7 · 숫자 24 · 간격 2 · 점 5) — 점이 생겨도
/// > 숫자가 올라가지 않는다.** State = Default · **Today(옅은 면 + 테두리, 오늘은
/// > 상태)** · Selected(채움, 선택) · Disabled(다른 달·지난 칸) · Empty(빈 칸).
/// > Dot = None · **Record(기록 있음, `bg/primary`)** · **Scheduled(예정, `amber/500`)**.
/// > **선택된 날은 숫자·기록 점이 흰색, 예정 점은 `amber/100`.**
/// > Day = Weekday · **Saturday(`fg/link`)** · **Sunday(`fg/danger`)**.
/// > 기존 `Date Cell`(점이 켜지면 숫자가 4px 올라감)을 대신하는 캘린더용 셀이다.
struct MMCalendarDay: View {
    enum State { case `default`, today, selected, disabled, empty }
    enum Dot { case none, record, scheduled }
    enum DayKind { case weekday, saturday, sunday }

    var date: Int?
    var state: State = .default
    var dot: Dot = .none
    var day: DayKind = .weekday
    var action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            VStack(spacing: CalendarMetrics.gap) {
                if state != .empty, let date {
                    // **숫자가 설 자리는 글자 배율과 상관없이 24다.** 줄 높이를 그대로
                    // 따르면 글자를 키워 쓰는 분의 기기에서 숫자가 자라 점을 면 밖으로
                    // 밀어내고, 면이 `clipShape`이라 **점이 통째로 사라진다** — 이 달에
                    // 무엇이 있었는지가 그 점뿐인데 그렇다. 글자는 그 자리 가운데에
                    // 그리고 넘쳐도 자르지 않는다. Android도 같은 자리를 같은 값으로
                    // 못박았다(`CalendarNumberHeight = 24`).
                    Text("\(date)")
                        .mmTextStyle(MMFont.bodyMStrong)
                        .foregroundStyle(numberColor)
                        .fixedSize()
                        .frame(height: CalendarMetrics.numberHeight)
                }
                if state != .empty, dot != .none {
                    Circle()
                        .fill(dotColor)
                        .frame(width: CalendarMetrics.dot, height: CalendarMetrics.dot)
                }
            }
            // 위 패딩을 고정해 점이 생겨도 숫자가 올라가지 않는다.
            .padding(.top, CalendarMetrics.topInset)
            .frame(width: CalendarMetrics.face, height: CalendarMetrics.face, alignment: .top)
            .background(faceColor)
            .clipShape(RoundedRectangle(cornerRadius: MMRadius.dateCell))
            .overlay {
                if state == .today {
                    RoundedRectangle(cornerRadius: MMRadius.dateCell)
                        .strokeBorder(MMColor.borderPrimary, lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: CalendarMetrics.cellHeight)
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || state == .empty || action == nil)
        .accessibilityHidden(state == .empty)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(state == .selected ? [.isSelected] : [])
    }

    private var faceColor: Color {
        switch state {
        case .selected: MMColor.bgPrimary
        case .today: MMColor.bgPrimaryFaint
        default: .clear
        }
    }

    private var numberColor: Color {
        switch state {
        case .selected: MMColor.fgOnPrimary
        case .disabled: MMColor.fgDisabled
        default:
            switch day {
            case .weekday: MMColor.fgDefault
            case .saturday: MMColor.fgLink
            case .sunday: MMColor.fgDanger
            }
        }
    }

    private var dotColor: Color {
        if state == .selected {
            return dot == .scheduled ? MMColor.dotScheduledOnPrimary : MMColor.fgOnPrimary
        }
        return dot == .scheduled ? MMColor.dotScheduled : MMColor.dotRecord
    }

    private var accessibilityText: String {
        guard let date else { return "" }
        let suffix = switch dot {
        case .none: ""
        case .record: ", 기록 있음"
        case .scheduled: ", 예정"
        }
        return "\(date)일\(suffix)\(state == .today ? ", 오늘" : "")"
    }
}

/// 디자인 시스템 `Calendar Grid` (Figma `3778:1868`).
///
/// Figma 설명 그대로:
/// > 한 달 캘린더 그리드 320 폭, 높이 Hug. 패딩 12/8, 줄 간격 4, 반경 20 ·
/// > `bg/surface` + `Elevation/Card`. **요일 줄(`Label/S` · 일 `fg/danger` · 토 `fg/link`
/// > · 나머지 `fg/subtle`)** + 주 6줄(7칸 모두 `Calendar Day`, 폭 Fill) +
/// > **범례(기록 있음 · 예정)**. **달이 5주면 Week 6을 끄고(기본), 6주면 켠다.**
struct MMCalendarGrid: View {
    /// 한 칸. 날짜가 `nil`이면 빈 칸이다.
    struct Day: Identifiable {
        let id = UUID()
        var date: Int?
        var state: MMCalendarDay.State = .default
        var dot: MMCalendarDay.Dot = .none

        static let empty = Day(date: nil, state: .empty)
    }

    /// 일요일부터 시작하는 칸 목록. 35칸이면 5주, 42칸이면 6주다.
    let days: [Day]
    var showsLegend: Bool = true
    var onPick: ((Int) -> Void)?

    private var weeks: [[Day]] {
        stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MMSpace.s4) {
            weekdayHeader

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { index, day in
                        MMCalendarDay(
                            date: day.date,
                            state: day.state,
                            dot: day.dot,
                            day: Self.kind(forColumn: index),
                            action: day.date.map { date in { onPick?(date) } }
                        )
                    }
                }
            }

            if showsLegend { legend }
        }
        .padding(.horizontal, MMSpace.s8)
        .padding(.vertical, MMSpace.s12)
        .background(MMColor.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg))
        .mmShadow(MMElevation.card)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(["일", "월", "화", "수", "목", "금", "토"].enumerated()), id: \.offset) { index, name in
                Text(name)
                    .mmTextStyle(MMFont.labelS)
                    .foregroundStyle(Self.headerColor(forColumn: index))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, MMSpace.s4)
    }

    private var legend: some View {
        HStack(spacing: MMSpace.s14) {
            legendItem(color: MMColor.dotRecord, text: "기록 있음")
            legendItem(color: MMColor.dotScheduled, text: "예정")
        }
        .padding(.horizontal, MMSpace.s10)
        .padding(.top, MMSpace.s10)
        .padding(.bottom, MMSpace.s2)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: CalendarMetrics.legendGap) {
            Circle()
                .fill(color)
                .frame(width: CalendarMetrics.legendDot, height: CalendarMetrics.legendDot)
            Text(text)
                .mmTextStyle(MMFont.labelS)
                .foregroundStyle(MMColor.fgSubtle)
        }
        .accessibilityElement(children: .combine)
    }

    static func kind(forColumn index: Int) -> MMCalendarDay.DayKind {
        switch index {
        case 0: .sunday
        case 6: .saturday
        default: .weekday
        }
    }

    static func headerColor(forColumn index: Int) -> Color {
        switch index {
        case 0: MMColor.fgDanger
        case 6: MMColor.fgLink
        default: MMColor.fgSubtle
        }
    }
}

enum CalendarMetrics {
    static let cellWidth: CGFloat = 44
    static let cellHeight: CGFloat = 46
    static let face: CGFloat = 42
    static let topInset: CGFloat = 7
    static let gap: CGFloat = MMSpace.s2
    static let dot: CGFloat = 5
    /// 숫자가 설 자리. 글자 배율을 따르지 않는다 — 따르면 점이 면 밖으로 밀려 잘린다.
    static let numberHeight: CGFloat = 24
    static let legendDot: CGFloat = 6
    static let legendGap: CGFloat = 5
}

#Preview {
    // 마스터 기본값: 2026년 9월(1일 화요일) · 4일 기록 · 18일 선택 · 21일 오늘 · 26일 예정
    let days: [MMCalendarGrid.Day] = {
        var list = [MMCalendarGrid.Day.empty, .empty]
        for date in 1...30 {
            var day = MMCalendarGrid.Day(date: date)
            if date == 4 { day.dot = .record }
            if date == 18 { day.state = .selected }
            if date == 21 { day.state = .today }
            if date == 26 { day.dot = .scheduled }
            list.append(day)
        }
        while list.count % 7 != 0 { list.append(.empty) }
        return list
    }()

    return MMCalendarGrid(days: days)
        .padding(MMSize.gutter)
        .background(MMColor.bgCanvas)
}
