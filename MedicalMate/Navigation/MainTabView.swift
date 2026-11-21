import SwiftUI

/// 하단 탭 셋과 유일한 네비게이션 스택.
///
/// 탭은 **캘린더 · 홈 · 기록**이고 홈이 가운데다. 내 정보는 탭이 아니라 홈 헤더의
/// 아바타로 들어간다.
///
/// 탭마다 스택을 따로 두지 않고 하나를 공유한다. Android가 단일 `NavHost`를 쓰는 것과
/// 같은 이유다 — 탭마다 스택을 두면 같은 화면이 탭 수만큼 쌓인다.
struct MainTabView: View {
    @Environment(\.appEnvironment) private var app
    @State private var tab: Tab = .home
    @State private var path = NavigationPath()
    @State private var mate: MateModel?

    var body: some View {
        NavigationStack(path: $path) {
            // 시스템 탭바를 쓰지 않는다. 디자인 시스템의 `Tab Bar`(319:1026)가 Glass
            // 86% · 채움 아이콘 전환으로 그려져 있고, 시스템 바로는 그 모양이 안 된다.
            ZStack(alignment: .bottom) {
                screen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                MMTabBar(selection: $tab)

                // 떠 있는 메이트 카드(J 섹션). 호출어가 정해지기 전에는 열리지 않는다.
                if let mate {
                    MateOverlay(model: mate)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .task {
                if mate == nil { mate = MateModel(appointments: app.appointments) }
            }
            .onChange(of: mate?.pending) { _, action in
                if let action { perform(action) }
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch tab {
        case .calendar:
            CalendarView(
                onOpenDay: { day, appointmentId in
                    path.append(Route.calendarDay(date: Self.wire(day), appointmentId: appointmentId))
                },
                onAddSchedule: { day, cardId in
                    path.append(Route.scheduleAdd(date: day.map(Self.wire), cardId: cardId))
                },
                onOpenCard: { id in
                    path.append(Route.briefCard(cardId: id))
                }
            )
        case .home:
            HomeView(
                onOpenCardList: { path.append(Route.briefCardList) },
                onOpenCard: { card in Int64(card.id).map { path.append(Route.briefCard(cardId: $0)) } },
                onStartIntake: { path.append(Route.intake(sessionId: nil)) },
                onProfile: { path.append(Route.myProfile) },
                onRecordVisit: { path.append(Route.clinicConfirm(cardId: $0)) },
                onOpenCardId: { path.append(Route.briefCard(cardId: $0)) },
                onScheduleCard: { path.append(Route.scheduleAdd(date: nil, cardId: $0)) },
                onTalkToMate: { Task { await mate?.open() } }
            )
        case .record:
            BriefCardListView(
                kind: .records,
                onOpenCard: { path.append(Route.briefCard(cardId: $0)) },
                onResumeIntake: { path.append(Route.intake(sessionId: $0)) },
                onOpenRecord: { path.append(Route.visitDetail(visitId: "\($0)")) },
                onStartIntake: { path.append(Route.intake(sessionId: nil)) }
            )
        }
    }

    /// 메이트가 말한 대로 옮긴다. 옮긴 뒤 카드는 "어디로 왔다"를 적은 채 남는다.
    private func perform(_ action: MateModel.Action) {
        switch action {
        case .tab(let destination):
            path = NavigationPath()
            tab = destination
        case .route(let route):
            path.append(route)
        case .back:
            if !path.isEmpty { path.removeLast() }
        }
        mate?.pending = nil
    }

    /// 라우트가 나르는 날짜. 서버와 같은 `yyyy-MM-dd`다.
    private static func wire(_ date: Date) -> String {
        VisitMapping.day(date, calendar: .current)
    }

    /// 화면이 붙는 대로 여기에 등록한다. **도메인별로 나눠 둔다** — 한 `switch`에 모으면
    /// 길이도 갈래도 한도를 넘는다.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .briefCardList, .briefCard, .recordDetail, .visitDetail:
            cardDestination(route)
        case .calendarDay, .scheduleAdd:
            calendarDestination(route)
        case .clinicConfirm, .hospitalPick, .visitNote, .visitRecord:
            visitDestination(route)
        case .myProfile, .healthEdit, .reminderTime:
            profileDestination(route)
        case .intake, .intakeDone, .onboardingIntro, .profileSetup, .profileComplete:
            intakeDestination(route)
        }
    }

    @ViewBuilder
    private func cardDestination(_ route: Route) -> some View {
        switch route {
        case .briefCardList:
            BriefCardListView(
                onOpenCard: { path.append(Route.briefCard(cardId: $0)) },
                onResumeIntake: { path.append(Route.intake(sessionId: $0)) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .briefCard(let cardId, let justCreated):
            BriefCardView(
                cardId: cardId,
                justCreated: justCreated,
                onBack: { path.removeLast() },
                onChangeHospital: { path.append(Route.hospitalPick) },
                onSchedule: { path.append(Route.scheduleAdd(date: nil, cardId: cardId)) },
                onViewSchedule: { day, id in
                    path.append(Route.calendarDay(date: Self.wire(day), appointmentId: id))
                },
                onRecordVisit: { path.append(Route.clinicConfirm(cardId: cardId)) },
                onDeleted: { path.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .recordDetail(let recordId):
            if let id = Int64(recordId) {
                RecordDetailView(
                    visitId: id,
                    onBack: { path.removeLast() },
                    onOpenCard: { path.append(Route.briefCard(cardId: $0)) }
                )
                .toolbar(.hidden, for: .navigationBar)
            }

        case .visitDetail(let visitId):
            if let id = Int64(visitId) {
                RecordDetailView(
                    visitId: id,
                    onBack: { path.removeLast() },
                    onOpenCard: { path.append(Route.briefCard(cardId: $0)) }
                )
                .toolbar(.hidden, for: .navigationBar)
            }

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func calendarDestination(_ route: Route) -> some View {
        switch route {
        case .calendarDay(let date, let appointmentId):
            if let day = HomeRepository.date(from: date) {
                CalendarDayView(
                    date: day,
                    appointmentId: appointmentId,
                    onBack: { path.removeLast() },
                    onOpenCard: { path.append(Route.briefCard(cardId: $0)) },
                    onRecordVisit: { path.append(Route.clinicConfirm(cardId: $0)) },
                    onOpenRecord: { path.append(Route.visitDetail(visitId: "\($0)")) },
                    onConfirmNextEvent: { day, cardId in
                        path.append(Route.scheduleAdd(date: Self.wire(day), cardId: cardId, isFollowUp: true))
                    },
                    onDeleted: { path.removeLast() }
                )
                .toolbar(.hidden, for: .navigationBar)
            }

        case .scheduleAdd(let date, let cardId, let isFollowUp):
            ScheduleAddView(
                initialDate: date.flatMap(HomeRepository.date(from:)),
                cardId: cardId,
                isFollowUp: isFollowUp,
                onBack: { path.removeLast() },
                onSaved: { _ in path.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func visitDestination(_ route: Route) -> some View {
        switch route {
        case .clinicConfirm(let cardId):
            VisitFlowView(
                cardId: cardId,
                onClose: { path.removeLast() },
                onSaved: { _ in path.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        default:
            PlaceholderView(title: "\(route)", note: "아직 그리지 않았다")
        }
    }

    @ViewBuilder
    private func profileDestination(_ route: Route) -> some View {
        switch route {
        case .myProfile:
            MyProfileView(
                onBack: { path.removeLast() },
                onEditHealth: { path.append(Route.healthEdit) },
                onEditReminderTime: { path.append(Route.reminderTime) },
                onLogout: { Task { await app.session.logOut() } },
                onWithdraw: { Task { _ = await app.session.withdraw() } }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .healthEdit:
            HealthEditView(
                onClose: { path.removeLast() },
                onSaved: { path.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .reminderTime:
            ReminderTimeView(
                onBack: { path.removeLast() },
                onSaved: { path.removeLast() }
            )
            .toolbar(.hidden, for: .navigationBar)

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func intakeDestination(_ route: Route) -> some View {
        switch route {
        case .intake(let sessionId):
            // 새로 시작하는 길은 1단계(인체도)가 짚은 부위를 넘겨줘야 열린다. 아직
            // 그 화면이 없어서 이어서 하는 길만 간다.
            if let sessionId {
                IntakeFlowView(
                    sessionId: sessionId,
                    onClose: { path.removeLast() },
                    onCardCreated: { path.append(Route.briefCard(cardId: $0, justCreated: true)) }
                )
                .toolbar(.hidden, for: .navigationBar)
            } else {
                PlaceholderView(title: "인체도", note: "1단계 `1c-1`이 서면 여기서 부위를 짚는다 (D5 미정)")
            }
        default:
            PlaceholderView(title: "\(route)", note: "아직 그리지 않았다")
        }
    }
}
