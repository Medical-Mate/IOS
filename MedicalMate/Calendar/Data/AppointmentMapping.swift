import Foundation

/// 응답을 화면 값으로 옮긴다.
enum AppointmentMapping {
    static func appointment(from response: AppointmentResponse) -> Appointment? {
        guard let on = HomeRepository.date(from: response.scheduledOn) else { return nil }
        let cards = (response.cards ?? []).map { AppointmentCard(id: $0.cardId, title: $0.title) }
        return Appointment(
            id: response.appointmentId,
            title: title(response, cards: cards),
            clinic: clinic(response),
            on: on,
            time: time(from: response.scheduledTime),
            status: AppointmentStatus.of(response.status),
            origin: AppointmentOrigin.of(response.origin),
            cards: cards,
            todos: (response.todos ?? []).map { AppointmentTodo(text: $0.text, isDone: $0.done ?? false) }
        )
    }

    /// 화면의 "서울OO병원 내과 재진".
    ///
    /// **셋이 다 비면 붙은 카드의 제목을 쓴다** — 제목 없는 줄은 무엇에 대한 일정인지
    /// 알 수 없다.
    static func title(_ response: AppointmentResponse, cards: [AppointmentCard]) -> String {
        let joined = [response.clinicName, response.department, response.purpose]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return joined.isEmpty ? (cards.first?.title ?? "") : joined
    }

    /// 병원 + 진료과. 목적은 뺀다.
    static func clinic(_ response: AppointmentResponse) -> String? {
        let joined = [response.clinicName, response.department]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    /// 서버가 주는 시각. `HH:mm:ss`로 오는데 **초를 생략한 판본도 있다.**
    ///
    /// **못 읽으면 시간 미정으로 본다** — 일정 하나 때문에 캘린더 전체가 죽는 것보다 낫다.
    static func time(from value: String?) -> AppointmentTime? {
        guard let value else { return nil }
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        return AppointmentTime(hour: parts[0], minute: parts[1])
    }

    /// 일정 줄의 둘째 줄. "오전 10:30 · 복부 통증 브리핑 카드".
    ///
    /// **시간이 미정이면 그 사실을 적는다** — 빈 자리로 두면 시간이 정해진 것처럼 읽힌다.
    static func meta(_ appointment: Appointment) -> String {
        let time = appointment.time?.label ?? "시간 미정"
        let card = appointment.cards.first?.title
        return [time, card].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// 일정 줄의 배지. 지난 일정은 "진료 완료"다.
    static func badge(_ appointment: Appointment) -> (text: String, tone: MMBadge.Tone)? {
        switch appointment.status {
        case .scheduled: ("진료 전", .brand)
        case .done: ("진료 완료", .success)
        case .canceled: nil
        }
    }

    /// 12시간 표기를 24시간으로. **오전 12시는 0시, 오후 12시는 12시다.**
    static func time(isMorning: Bool, hour: Int, minute: Int) -> AppointmentTime {
        let base = hour % 12
        return AppointmentTime(hour: isMorning ? base : base + 12, minute: minute)
    }

    /// 빈 줄은 보내지 않는다. **추가만 누르고 안 적은 칸이다.**
    static func cleaned(_ todos: [AppointmentTodo]) -> [TodoResponse] {
        todos
            .map { todo in
                TodoResponse(
                    text: todo.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    done: todo.isDone
                )
            }
            .filter { !$0.text.isEmpty }
    }
}
