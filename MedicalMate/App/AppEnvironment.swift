import Foundation

/// 조립 루트.
///
/// Hilt 같은 컴파일타임 DI가 iOS에 없어서 여기서 손으로 엮는다. **의존 그래프가 한
/// 파일에 다 보이는 것이 이 방식의 장점이다.** 화면은 이 타입을 모른다 — 필요한 것만
/// 생성자나 Environment로 받는다.
@MainActor
final class AppEnvironment {
    let tokens: TokenStore
    let client: ApiClient
    let auth: AuthRepository
    let healthProfile: HealthProfileRepository
    let settings: SettingsRepository
    let home: HomeRepository
    let cards: CardRepository
    let intake: IntakeRepository
    let hospitals: HospitalRepository
    let visits: VisitRepository
    let appointments: AppointmentRepository
    /// 다가오는 일정으로 기기 알림을 다시 거는 쪽.
    let reminders: VisitReminders
    let session: SessionModel

    init(kakao: any KakaoLoginClient = UnavailableKakaoLoginClient()) {
        let tokens = TokenStore()
        self.tokens = tokens

        // 재발급은 `ApiClient`를 쓰는데 그 클라이언트를 만들 때 재발급기가 필요하다.
        // 늦게 꽂아 순환을 끊는다. Android는 `@AuthFree` Retrofit을 따로 만들어 풀었다.
        let holder = ClientHolder()
        let refresher = ServerTokenRefresher { holder.client }

        // 세션 모델도 늦게 꽂는다. 재발급이 끝내 실패하면 로그인 화면으로 보내야 하는데
        // 그 모델은 아래에서 만들어진다.
        let sessionHolder = SessionHolder()
        let client = ApiClient(
            baseURL: AppConfig.backendBaseURL,
            tokens: tokens,
            refresher: refresher,
            onSessionExpired: { await sessionHolder.session?.sessionExpired() }
        )
        holder.client = client
        self.client = client

        self.healthProfile = HealthProfileRepository(client: client)
        self.settings = SettingsRepository(client: client)
        self.home = HomeRepository(client: client)
        self.cards = CardRepository(client: client)
        self.intake = IntakeRepository(client: client)
        self.hospitals = HospitalRepository(client: client)
        self.visits = VisitRepository(client: client)
        let appointments = AppointmentRepository(client: client)
        self.appointments = appointments
        self.reminders = VisitReminders(
            appointments: appointments,
            settings: SettingsRepository(client: client),
            scheduler: VisitReminderScheduler()
        )

        let remote = AuthRemote(client: client)
        let auth = AuthRepository(remote: remote, kakao: kakao, tokens: tokens)
        self.auth = auth
        let session = SessionModel(tokens: tokens, auth: auth, reminders: self.reminders)
        self.session = session
        sessionHolder.session = session
    }
}

/// 세션 모델과 클라이언트의 순환을 끊는 상자. ``ClientHolder``와 같은 이유다.
@MainActor
private final class SessionHolder {
    var session: SessionModel?
}

/// 재발급기와 클라이언트의 순환을 끊는 상자.
private final class ClientHolder: @unchecked Sendable {
    var client: ApiClient?
}

/// 빌드 설정에서 온 값.
///
/// 백엔드 주소와 카카오 앱 키는 `Config/Base.xcconfig`에서 `Info.plist`로 들어온다.
/// **앱 키를 소스에 적지 않는다.** 없으면 빈 문자열이고 빌드는 통과한다 — 실패는 카카오
/// API를 부를 때만 난다. Android의 `local.properties` 규칙과 같다.
enum AppConfig {
    static var backendBaseURL: URL {
        let value = infoString("BackendBaseURL") ?? ""
        guard let url = URL(string: value) else {
            fatalError("BackendBaseURL이 비었거나 잘못됐다. Config/Base.xcconfig를 본다.")
        }
        return url
    }

    static var kakaoNativeAppKey: String {
        infoString("KakaoNativeAppKey") ?? ""
    }

    static var isKakaoConfigured: Bool { !kakaoNativeAppKey.isEmpty }

    private static func infoString(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else { return nil }
        return value
    }
}
