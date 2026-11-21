import Foundation

/// 한 달의 칸을 만든다.
///
/// **일요일부터 시작한다.** 35칸이면 5주, 42칸이면 6주이고 `Calendar Grid`가 그만큼만
/// 그린다 — 마스터도 "5주면 Week 6을 끄고 6주면 켠다"고 적었다.
struct CalendarMonth: Sendable, Equatable {
    let year: Int
    let month: Int

    /// 화면 머리의 "2026년 9월".
    var title: String { "\(year)년 \(month)월" }

    static func of(_ date: Date, calendar: Calendar) -> CalendarMonth {
        let components = calendar.dateComponents([.year, .month], from: date)
        return CalendarMonth(year: components.year ?? 0, month: components.month ?? 0)
    }

    func advanced(by months: Int, calendar: Calendar) -> CalendarMonth {
        guard let start = firstDay(calendar: calendar),
              let moved = calendar.date(byAdding: .month, value: months, to: start) else { return self }
        return .of(moved, calendar: calendar)
    }

    func firstDay(calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }

    func date(day: Int, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    /// 이 달의 날수.
    func dayCount(calendar: Calendar) -> Int {
        guard let start = firstDay(calendar: calendar),
              let range = calendar.range(of: .day, in: .month, for: start) else { return 0 }
        return range.count
    }

    /// 1일이 어느 요일 칸에 놓이는지. 일요일이 0이다.
    func leadingBlanks(calendar: Calendar) -> Int {
        guard let start = firstDay(calendar: calendar) else { return 0 }
        return (calendar.component(.weekday, from: start) - 1 + 7) % 7
    }

    /// 그리드 칸을 만든다.
    ///
    /// - Parameters:
    ///   - selected: 고른 날. 채운 칸이 된다.
    ///   - today: 오늘. 옅은 면 + 테두리다. **오늘이 선택보다 앞선다** — 1r-1에서
    ///     오늘(7)은 테두리, 고른 날(12)은 채움이고, 고른 날이 오늘이면(일정 없을 때의
    ///     18) 테두리로 그려져 있다.
    ///   - scheduled: 일정이 있는 날.
    ///   - records: 기록이 있는 날.
    func days(
        calendar: Calendar,
        selected: Int?,
        today: Int?,
        scheduled: Set<Int>,
        records: Set<Int>
    ) -> [MMCalendarGrid.Day] {
        let blanks = leadingBlanks(calendar: calendar)
        let count = dayCount(calendar: calendar)
        var cells: [MMCalendarGrid.Day] = Array(repeating: .empty, count: blanks)

        for day in 1...max(count, 1) where count > 0 {
            let state: MMCalendarDay.State =
                if day == today { .today }
                else if day == selected { .selected }
                else { .default }
            // **기록이 예정보다 앞선다.** 이미 지난 일은 사실이고 예정은 계획이다
            // (Android `markerOn`과 같다).
            let dot: MMCalendarDay.Dot =
                if records.contains(day) { .record }
                else if scheduled.contains(day) { .scheduled }
                else { .none }
            cells.append(MMCalendarGrid.Day(date: day, state: state, dot: dot))
        }

        // 뒤를 빈 칸으로 채워 주 단위로 떨어뜨린다.
        let weeks = Int(ceil(Double(cells.count) / 7))
        cells.append(contentsOf: Array(repeating: .empty, count: weeks * 7 - cells.count))
        return cells
    }

    /// 구간 제목의 "9월 12일 (토)".
    static func dayTitle(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.month, .day, .weekday], from: date)
        let weekday = HomeRepository.weekdays[(components.weekday ?? 1) - 1]
        return "\(components.month ?? 0)월 \(components.day ?? 0)일 (\(weekday))"
    }
}
