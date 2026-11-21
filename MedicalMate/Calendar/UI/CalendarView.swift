import SwiftUI

/// `1r-1 · 캘린더 · 월` (Figma `3663:15299`).
///
/// 달 그리드 + 고른 날의 일정 목록. 일정이 없으면 그 자리에 빈 안내가 선다
/// (`1r-1 일정 없을 때` `3663:14676`).
struct CalendarView: View {
    @Environment(\.appEnvironment) private var app

    var onOpenDay: (Date) -> Void = { _ in }
    var onAddSchedule: (Date?) -> Void = { _ in }

    @State private var model: CalendarModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .task {
            guard model == nil else { return }
            let created = CalendarModel(repository: app.appointments)
            model = created
            await created.load()
        }
    }

    private func content(_ model: CalendarModel) -> some View {
        VStack(spacing: 0) {
            MMNavBar(title: "캘린더", leading: .none)

            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: MMSpace.s14) {
                        monthHead(model)

                        MMCalendarGrid(days: model.days) { day in
                            model.select(day: day)
                        }

                        MMSectionHeader(title: model.selectedTitle)

                        // 일정이 없으면 **아무것도 그리지 않는다.** 마스터
                        // (`3663:14676`)가 구간 제목 아래를 비워 둔다.
                        ForEach(model.selectedAppointments) { appointment in
                            row(appointment, model: model)
                        }

                        if let message = model.errorMessage {
                            Text(message)
                                .mmTextStyle(MMFont.bodyS)
                                .foregroundStyle(MMColor.fgDanger)
                        }
                    }
                    .padding(.horizontal, MMSize.gutter)
                    .padding(.top, MMSpace.s8)
                    .padding(.bottom, CalendarScreenMetrics.scrollBottom)
                }
                .scrollBounceBehavior(.basedOnSize)

                MMIconButton(icon: .plus, label: "일정 추가", style: .solid, size: .l) {
                    onAddSchedule(model.selectedDate)
                }
                .mmShadow(MMElevation.float)
                .padding(.trailing, MMSize.gutter)
                .padding(.bottom, CalendarScreenMetrics.fabBottom)
            }
        }
        .background(MMColor.bgSurface)
    }

    private func monthHead(_ model: CalendarModel) -> some View {
        HStack(spacing: MMSpace.s8) {
            MMIconButton(icon: .chevronLeft, label: "이전 달") {
                Task { await model.goToPreviousMonth() }
            }
            Text(model.month.title)
                .mmTextStyle(MMFont.headingM)
                .foregroundStyle(MMColor.fgDefault)
                .frame(maxWidth: .infinity)
            MMIconButton(icon: .chevronRight, label: "다음 달") {
                Task { await model.goToNextMonth() }
            }
        }
    }

    private func row(_ appointment: Appointment, model: CalendarModel) -> some View {
        MMListRow(
            title: appointment.title,
            meta: AppointmentMapping.meta(appointment),
            badge: AppointmentMapping.badge(appointment),
            action: { model.selectedDate.map(onOpenDay) }
        )
    }
}

private enum CalendarScreenMetrics {
    /// 탭바와 FAB가 가리지 않게 비우는 아래 여백.
    static let scrollBottom: CGFloat = MMSize.tabBarHeight + 60
    /// FAB가 탭바 위에 뜨는 높이.
    static let fabBottom: CGFloat = MMSize.tabBarHeight + 20
}
