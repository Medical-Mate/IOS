import Foundation

/// 앱의 목적지.
///
/// **문자열 경로를 쓰지 않는다.** 값 타입으로 두면 인자를 컴파일러가 검사한다.
/// Android의 타입 세이프 라우트(`@Serializable data object` / `data class`)와 같은 자리다.
///
/// 라우트는 기능 폴더가 아니라 여기 모은다 — Swift는 `NavigationPath`가 하나의
/// `Hashable` 집합을 요구해서 Android처럼 기능별 파일에 흩어 두면 `navigationDestination`
/// 등록이 갈린다. 화면 View 자체는 기능 폴더에 둔다.
enum Route: Hashable, Sendable {
    // 진입
    case onboardingIntro
    case profileSetup
    case profileComplete

    // 증상 정리
    case intake(sessionId: Int64?)
    case intakeDone(sessionId: Int64?)

    // 카드·기록
    /// `justCreated`면 일정 시트(1e-1-S)가 먼저 뜬다.
    case briefCard(cardId: Int64, justCreated: Bool = false)
    case briefCardList
    case recordDetail(recordId: String)

    // 캘린더
    case calendarDay(date: String, appointmentId: Int64?)
    /// 일정 추가. **재방문을 확정하러 들어오면** 그 카드를 들고 간다 — 만들어진 일정이
    /// 무엇 하러 가는 날인지 남아야 다음 일정으로 다시 찾을 수 있다(`1r-2-A`).
    /// 일정 추가. `cardId`는 **미리 골라 둘 카드**이고, `isFollowUp`은 **진료 후 기록의
    /// 재방문을 확정하러 들어온 것인지**다. 둘은 다른 뜻이라 따로 든다 — 카드를 들고
    /// 들어가는 길(카드만 있는 날 시트 · 홈 배너 · 브리핑 카드)은 재방문이 아니다.
    /// Android `ScheduleAddDestination`도 `cardId`와 `followUp`을 따로 둔다(#239 · #245).
    case scheduleAdd(date: String?, cardId: Int64? = nil, isFollowUp: Bool = false)

    // 진료 후 기록
    case hospitalPick
    case clinicConfirm(cardId: Int64)
    case visitNote(cardId: Int64)
    case visitRecord(cardId: Int64)
    case visitDetail(visitId: String)

    // 내 정보
    case myProfile
    case healthEdit
    case reminderTime
}

/// 하단 탭. 홈이 가운데다.
///
/// **내 정보는 탭이 아니다.** 홈 헤더의 아바타로 들어간다. 마스터에 네 번째 variant가
/// 있지만 앱은 쓰지 않는다.
enum Tab: Hashable, CaseIterable, Sendable {
    case calendar
    case home
    case record
}
