# 진료메이트 iOS — 기능명세서

| 항목 | 값 |
| -- | -- |
| 문서 판 | v1.0 (2026-11-20) |
| 출처 | `Medical-Mate/Android` main 브랜치 소스 — 네비게이션 라우트 20종, Retrofit API 9개, 도메인 모델, `CLAUDE.md` 8장 현재 상태표 |
| 읽는 법 | 화면 ID는 Figma 와이어프레임 번호(`1n`, `1e-1` 등)를 그대로 쓴다. iOS 화면 이름은 Android 라우트 이름을 따른다 |

> **확인되지 않은 것은 "미정"으로 적었다.** 백엔드 OpenAPI 문서와 Figma 원본을 직접 읽지
> 않았으므로, 요청/응답 필드는 Android 클라이언트가 실제로 보내고 받는 것만 적었다.
> 서버가 더 많은 필드를 줄 수 있다.

---

## 1. 화면 목록

Android는 단일 `NavHost`에 목적지 23개다. 라우트 타입은 20종이고 나머지는 스플래시·세션
분기 같은 비라우트 상태다.

| # | 화면 ID | Android 라우트 | 역할 | 인자 |
| -- | -- | -- | -- | -- |
| 1 | 1a-1 | (MainActivity 로딩) | 스플래시 · 세션 확인 | — |
| 2 | 1o | `LoginDestination` | 카카오 로그인 | — |
| 3 | ONB-00~03 | `OnboardingIntroDestination` | 소개 4장 | — |
| 4 | 1b-1~3 | `ProfileSetupDestination` | 신상정보 3단계 | — |
| 5 | 1b-4 | `ProfileCompleteDestination` | 등록 완료 모션 | — |
| 6 | 1n | `HomeDestination` | 홈 | — |
| 7 | 1l · 1d · 1c | `IntakeDestination` | 증상 정리 3단계 | `sessionId: Long?`, `spoken: String?` |
| 8 | 1c-D4 | `IntakeDoneDestination` | 정리 완료 | `sessionId: Long?` |
| 9 | 1e-1 | `BriefCardDestination` | 브리핑 카드 읽기/편집 | 카드 식별자 |
| 10 | 1j-4 | `BriefCardListDestination` | 브리핑 카드 전체 목록 | — |
| 11 | 1j-1 | `RecordDestination` | 기록 월별 목록 | — |
| 12 | 1j-3 | `RecordDetailDestination` | 기록 상세 타임라인 | `recordId: String` |
| 13 | 1r-1 | `CalendarDestination` | 캘린더 월 화면 | — |
| 14 | 1r-2 | `CalendarDayDestination` | 캘린더 일자 화면 | `date: String`, `appointmentId: Long?` |
| 15 | 1r-4 | `ScheduleAddDestination` | 일정 추가/수정 | 날짜 · 카드 · 공유 텍스트 |
| 16 | 1m | `HospitalPickDestination` | 병원 찾기 | |
| 17 | 1m-12 | `ClinicConfirmDestination` | 병원 확인 | |
| 18 | 1p | `VisitNoteDestination` | 진료 후 메모 작성 | |
| 19 | 1q-1 | `VisitRecordDestination` | AI 분류 결과 확인/저장 | |
| 20 | 1q-2 | `VisitDetailDestination` | 진료 후 기록 상세 | `visitId: String` |
| 21 | 1s-1 | `MyProfileDestination` | 내 정보 | — |
| 22 | 1s-3 | `HealthEditDestination` | 건강 정보 수정 | — |
| 23 | 1s-x | `ReminderTimeDestination` | 알림 시각 설정 | — |

하단 탭은 **캘린더 · 홈 · 기록** 셋이고 홈이 가운데다. 내 정보는 탭이 아니라 홈 헤더의
아바타로 들어간다.

---

## 2. 기능 명세

### 2.1 인증 (`auth`)

| 항목 | 명세 |
| -- | -- |
| 로그인 | 카카오 SDK로 인가 → 서버에 `POST /api/auth/kakao`로 교환 → 서버 JWT(access + refresh) 수신 |
| 토큰 저장 | 서버 JWT만 저장한다. 카카오 토큰은 SDK가 보관하므로 앱이 따로 저장하지 않는다 |
| 자동 재발급 | 401을 받으면 refresh 토큰으로 `POST /api/auth/refresh` 후 원 요청을 **한 번만** 재시도 |
| 재발급 격리 | 재발급 호출은 **인증 헤더를 붙이지 않는 별도 HTTP 클라이언트**로 나간다. 같은 클라이언트를 쓰면 만료 헤더로 나가 401이 재귀한다 |
| 로그아웃 | `POST /api/auth/logout` 후 토큰 삭제 + 화면 스택을 루트까지 비우며 로그인으로 |
| 회원탈퇴 | `DELETE /api/me`. 내 정보 하단, 로그아웃 아래 텍스트 버튼 |
| 계정 전환 | 로그아웃 시 화면별 상태 객체가 함께 파기되어 이전 계정 데이터가 남지 않아야 한다 |
| refresh TTL | 30일 |

**기존 결함(iOS에서 고칠 것):** 탈퇴 후 재가입하면 온보딩 기록이 로컬에 남아 온보딩이
건너뛰어진다. 서버 `onboardingCompleted`를 정본으로 삼으면 사라진다.

### 2.2 온보딩 · 프로필 (`profile`)

| 항목 | 명세 |
| -- | -- |
| 온보딩 노출 판단 | 서버 `onboardingRequired`와 로컬 저장값을 함께 본다. `refresh` 응답은 항상 false다 |
| 신상정보 3단계 | 복용약 → 기저질환 → 알러지. 각각 칩 목록 입력 |
| 값 상태 | 각 갈래는 `KNOWN` / `NONE`(없다) / `UNKNOWN`(모른다) 세 상태. **화면에 "없음"과 "모름"을 가르는 자리가 없어 비어 있으면 `UNKNOWN`으로 보낸다.** 알러지에서 두 값은 처방이 달라지므로 단정하면 안 된다 |
| 카카오에서 오는 값 | `name` · `birthYear` · `sex`. 화면이 쓰지 않아도 저장 시 그대로 되돌려 보내야 한다 |
| API | `GET/PUT /api/me/health-profile`, `GET/PATCH /api/me/settings` |

```swift
// 도메인 모델 (Android HealthProfile 대응)
struct HealthProfile {
    var name: String?
    var birthYear: Int?
    var birthMonthDay: String?
    var sex: String?
    var health: HealthEdit          // medications / conditions / allergies
    var onboardingCompleted: Bool
    var canStartIntake: Bool
}
struct HealthField { var items: [String] = []; var status: HealthStatus = .unknown }
enum HealthStatus { case known, none, unknown }
```

### 2.3 증상 정리 (`intake`)

**3단계다.** 진행 표시는 `n / 3`.

| 단계 | 화면 | 하는 일 |
| -- | -- | -- |
| 1 | 3D 인체도 | 아픈 부위를 **한 곳만** 고른다. 전신 → 구역 확대 → 부위. 목록에서 고르기와 검색도 있다 |
| 2 | 1d | 통증 강도를 1~5 서열척도로 고른다 |
| 3 | 1c-2 · 1c-3 | AI와 문답 → 끝나면 같은 대화 아래에 추천 질문 줄이 서고 고른다 |

**세션 생명주기 (중요):**

1. 세션은 **강도를 고르고 "다음"을 누를 때 연다.** 부위 + 강도를 `POST /api/sessions`에 함께 보낸다.
2. 강도로 돌아가 다시 고르면 세션을 새로 열지 않고 `PUT /api/sessions/{id}/severity`로 그 값만 고친다.
3. **부위를 바꿔 다시 오면 그 세션은 버리고 새로 연다.**
4. 문답은 `POST /api/sessions/{id}/messages` 한 턴씩. 응답의 `ended`가 서면 끝이다. 끝난 뒤 또 보내도 오류가 아니라 마지막 문장만 돌아온다.
5. 추천 질문은 **문답이 끝난 턴의 응답(`questionCandidates`)에 실려 온다.** `rank` 순이다.
6. 고른 질문만 화면 차례대로 `PUT /api/sessions/{id}/questions`에 보낸다.
7. 카드 생성은 `POST /api/sessions/{id}/card`.

**질문 규칙:**
- 최대 5개. 상한은 단일 상수로 두고 3단계와 카드 편집(1e-1-E)이 함께 쓴다.
- 다섯 개가 차면 더 체크되지 않고 "직접 추가" 빈 칸이 사라진다.
- 환자가 한 번이라도 손댔으면 서버 후보로 덮지 않는다. 덮으면 지운 질문이 되살아난다.
- 서버가 상한을 넘기면 `PUT /questions`를 거절한다. **결과를 버리지 말고 화면에 알려야 한다** (Android의 알려진 결함).

**음성 입력 규칙:**
- 마이크를 누르면 바로 듣는다. 말하는 글이 대화에 미리 선다.
- **말이 1초 끊기면 누르지 않아도 그 자리에서 보낸다.** 받아쓴 글이 들어올 때마다 타이머를 처음부터 다시 센다.
- **듣기 시작하고 5초 동안 아무 말이 없으면 패널을 닫는다.**
- 패널이 떠 있을 때 뒤로가기(iOS: 스와이프/닫기)는 받아쓰기만 끈다. 화면을 나가지 않는다.
- 끄면 입력칸은 음성을 켜기 전에 적은 글로 되돌린다.
- 문답이 끝나면 "다음"이라고 말해 넘어갈 수 있다.
- **받아쓰기가 불가능한 기기에서는 마이크를 그리지 않는다.**

**부위 선택 상태 규칙:** `focus`(확대한 앵커)와 `selection`(고른 부위)을 **분리한다.**
하나로 두면 구역을 고르는 순간 화면이 앵커 단계로 되돌아간다.

```swift
struct IntakeSession {
    let id: Int64
    var status: IntakeSessionStatus      // inProgress / completed / abandoned
    var siteCodes: [String]
    var siteText: String?
    var answered: Int
    var total: Int
    var messages: [IntakeSessionMessage] // seq, fromPatient, text
    var severityLevel: Int?              // 1...5
    var questions: [String]              // 환자가 확정한 것, 화면 순서
    var questionCandidates: [String]     // AI 추천, rank 순
}
```

### 2.4 브리핑 카드 (`card`)

| 항목 | 명세 |
| -- | -- |
| 생성 | `POST /api/sessions/{sessionId}/card` |
| 읽기 | `GET /api/cards/{cardId}` |
| 목록 | `GET /api/me/cards` — 제목 · 진료 완료 뱃지 · 병원 · 작성일 |
| 편집 | `PATCH /api/cards/{cardId}`. 축 단위로 `{"axis":"onset","value":"3주 전"}` 모양 |
| 삭제 | `DELETE /api/cards/{cardId}` |
| 버전 | **확정된 카드를 고치면 서버가 새 버전을 만든다.** 앱은 응답의 카드를 다시 그린다 |
| 뱃지 | "진료 완료"는 `visited`로 판단한다. 병원명은 선택 입력이라 비어 있을 수 있으므로 그것으로 판단하면 안 된다 |
| 제목 | 서버가 `title`을 안 주면 `chiefComplaint`를 24자로 줄이고 말줄임을 붙인다 |
| 목록 병원 | "진료받을 병원"(`clinic.name`)이 먼저고, 없으면 진료받은 병원(`clinicName`) |
| 카드 칩 | 네 가지 — 작성 중 / 임시 저장 / 진료 전 / 진료 완료. 홈의 최근 카드에는 "작성 중"이 빠진다(카드는 만들 때부터 확정) |
| 미생성 세션 | `GET /api/me/home`의 열린 세션이 목록에 한 줄로 선다. `questionsConfirmed=false`면 "작성 중", true면 "임시 저장". 버리기는 `DELETE /api/sessions/{id}` |
| 내보내기 | 카드 이미지 저장 · 공유 |

### 2.5 진료 후 기록 (`visit`)

흐름: **병원 확인(1m-12) → 메모(1p) → AI 분류 확인(1q-1) → 저장**

| 항목 | 명세 |
| -- | -- |
| 병원 검색 | `GET /api/hospitals?q=&size=` |
| 메모 분류 | `POST /api/visits/classify` |
| 저장 | `POST /api/cards/{cardId}/visit` |
| 목록 | `GET /api/me/visits`, 카드별 `GET /api/cards/{cardId}/visits` |
| 상세 | `GET /api/visits/{visitId}` |
| 삭제 | `DELETE /api/visits/{visitId}` |
| 필수 입력 | **없다.** 메모 원문만 있어도 저장된다. 병원을 막 나온 사람에게 필수 입력을 요구하면 아무것도 안 남는다 |
| 항목 가변 | 축 목록이고 AI가 축을 늘려도 실린다. 값이 없는 항목은 줄을 그리지 않는다 |
| 재방문 | `approximate`면 환자가 "2주 뒤"처럼 말한 것. 화면은 "9월 27일 전후"로 적는다 |
| **재방문 자동 일정 금지** | 서버는 저장만 하고 **캘린더 일정은 환자가 보고 정하는 흐름(1r-2-A)으로만 만든다.** AI가 날짜를 잘못 뽑을 수 있어 조용히 일정이 생기면 안 된다 |
| 카드 삭제 내성 | 카드를 지워도 기록은 남고 연결만 끊긴다. 줄 제목은 기록에 박아둔 `cardTitle`로 그린다 |

**온디바이스 분류 3단계 (모델이 있을 때):**
1. 서버가 모델 없이 문장만 나눈다 (`classify: false`). **폰이 문장을 나누지 않는다** — 폰과 서버가 같은 번호를 가리켜야 서버가 라벨로 카드를 조립한다.
2. 폰이 문장마다 라벨을 붙인다. 메모 원문이 외부 AI로 가지 않는다.
3. 라벨을 서버에 보내 조립한다. 모델을 부르지 않는다.

`labels`를 들고 있다가 다시 나눌 때 돌려준다. 그것이 AI 모델을 다시 부르지 않게 하는
유일한 방법이다.

### 2.6 캘린더 (`calendar`)

| 항목 | 명세 |
| -- | -- |
| 목록 | `GET /api/me/appointments` (기간), `GET /api/me/appointments/upcoming` |
| 생성 | `POST /api/me/appointments` — **날짜만 필수.** 시각 없으면 "시간 미정" |
| 수정 | `PATCH /api/me/appointments/{id}` — `null`은 "안 바꿈". 시각을 미정으로 되돌리려면 `clearTime` 플래그가 따로 필요하다 |
| 삭제 | `DELETE /api/me/appointments/{id}` |
| 카드 연결 | 여러 장 붙을 수 있다. 화면은 한 장만 고르게 하지만 모델은 목록으로 들고 있는다. 수정 시 **통째로 갈아끼운다** (`nil`=안 바꿈, `[]`=전부 뗌) |
| 할 일 | 진료 전 할 일 줄. 서버가 id를 매기지 않으므로 **화면 key는 앱이 차례로 만든다** (같은 글이 두 줄 있을 수 있어 글을 key로 쓸 수 없다) |
| 제목 조합 | 서버가 제목을 주지 않는다. 병원 · 진료과 · 목적 세 필드를 앱이 조합한다 ("서울OO병원 내과 재진") |
| 출처 | `MANUAL` / `VISIT_FOLLOW_UP`. **모르는 값은 `MANUAL`로 본다** — 서버가 갈래를 늘렸을 때 일정을 잃는 것보다 낫다 |
| 상태 | `SCHEDULED` / `DONE` / `CANCELED` |

### 2.7 알림

| 알림 | 시점 | 내용 |
| -- | -- | -- |
| 진료 전 알림 | 시각을 정한 일정은 진료 전, 시간 미정이면 사용자 설정 시각 | 병원 · 진료과를 본문에 적는다 |
| 진료 후 기록 알림 | 진료 시각 이후 | 기록하러 들어오게 한다 |

로컬 알림이다. 서버 푸시가 아니다. 알림 시각은 내 정보에서 바꾼다.

### 2.8 예약 문자 가져오기

문자 앱의 공유 메뉴에 "진료메이트"로 뜨고, 받은 텍스트에서 병원 · 날짜 · 시각을 뽑아
**일정 추가 화면이 채워진 채 열린다.**

### 2.9 홈

위에서부터: 사진 배너(5장, 4초마다 0.5초 전환, 끝에서 첫 장으로 순환) → 흰 시트가
28pt 겹쳐 올라옴 → 증상 정리 시작하기 → 이어서 하기(진행 원 n/3) → 최근 브리핑 카드
2장 → 다가오는 일정.

**첫 배너는 상황에 따라 바뀐다:**

| 조건 | 문구 | 링크 |
| -- | -- | -- |
| 오늘 카드가 걸린 진료가 있고 아직 기록 안 함 | "진료 잘 다녀오셨나요?" | 진료 후 기록하기 (1m-12 → 1p) |
| 내일 진료 | "내일 진료 전에 카드 한 번 볼까요?" | 카드 다시 보기 |
| 최근 카드가 진료 전이고 일정이 없음 | "카드는 준비됐어요" | 진료 일정 잡기 |
| 카드 · 일정 · 진료 모두 없음 | "처음 오셨네요" | (넘김 없는 한 장) |
| 그 밖 | 2~5장 중 무작위 하나를 첫 장에 | 화면이 살아 있는 동안 같은 장 유지 |

- 손으로 넘기는 동안은 자동 전환을 세지 않는다.
- **기기에서 애니메이션을 껐으면 저절로 넘기지 않는다** (iOS: Reduce Motion).
- 일정 없는 카드인지는 홈 응답에 없어 그 카드를 `GET /api/cards/{id}`로 한 번 더 읽는다.
- 읽지 않은 알림 표시는 늘 꺼 둔다 — 대응 API가 없다.
- API: `GET /api/me/home`

### 2.10 음성 명령 (호출어)

앱을 쓰는 동안 "헤이 메이트"라고 부르면 음성 패널이 뜨고 말한 대로 화면을 옮긴다
(홈 · 캘린더 · 기록 · 내 정보 · 뒤로 · 증상 정리 등). 화면마다 쓸 수 있는 명령이 다르고,
명령 해석 상태는 **화면이 아니라 앱 수명에 묶인다** — 화면을 옮겨도 듣기가 끊기면 안 된다.

> iOS에서 이 기능을 그대로 할 수 있는지는 별도 결정 사항이다. → `AOS-IOS-DIFF.md` 4장

---

## 3. API 요약

Android 클라이언트가 실제로 호출하는 전부다.

| 도메인 | 메서드 | 경로 |
| -- | -- | -- |
| auth | POST | `/api/auth/kakao` |
| auth | POST | `/api/auth/refresh` |
| auth | POST | `/api/auth/logout` |
| auth | DELETE | `/api/me` |
| profile | GET / PUT | `/api/me/health-profile` |
| profile | GET / PATCH | `/api/me/settings` |
| home | GET | `/api/me/home` |
| intake | POST | `/api/sessions` |
| intake | GET | `/api/sessions/{sessionId}` |
| intake | POST | `/api/sessions/{sessionId}/messages` |
| intake | PUT | `/api/sessions/{sessionId}/severity` |
| intake | PUT | `/api/sessions/{sessionId}/questions` |
| intake | POST | `/api/sessions/{sessionId}/question-candidates` |
| intake | DELETE | `/api/sessions/{sessionId}` |
| card | POST | `/api/sessions/{sessionId}/card` |
| card | GET | `/api/me/cards` |
| card | GET / PATCH / DELETE | `/api/cards/{cardId}` |
| visit | GET | `/api/me/visits` |
| visit | GET | `/api/visits/{visitId}` |
| visit | GET | `/api/cards/{cardId}/visits` |
| visit | POST | `/api/cards/{cardId}/visit` |
| visit | DELETE | `/api/visits/{visitId}` |
| visit | POST | `/api/visits/classify` |
| hospital | GET | `/api/hospitals?q=&size=` |
| calendar | GET | `/api/me/appointments` |
| calendar | GET | `/api/me/appointments/upcoming` |
| calendar | POST | `/api/me/appointments` |
| calendar | PATCH / DELETE | `/api/me/appointments/{appointmentId}` |

**오류 처리 계약:** API 실패는 예외가 아니라 값이다. `Success` / `Rejected` / `NetworkUnavailable`
세 갈래로 받고, 직렬화 실패 같은 **계약 위반은 잡지 않는다.** "다시 시도해주세요"로 감추면
원인을 찾을 수 없게 된다.

---

## 4. 디자인 시스템 요약

| 묶음 | 값 |
| -- | -- |
| 캔버스 | 360×812, 콘텐츠 320, 좌우 거터 20 |
| 간격 | 2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 · 20 · 24 · 32 · 40 |
| 크기 | 터치 최소 48(iOS는 44 검토), 아이콘 18/20/24, 컨트롤 40/48/56, 마이크 88 |
| 내비 | 상단 56, 하단 탭 79 |
| 색 | 시맨틱 토큰 44종 (`bg/*`, `fg/*`, `border/*`). **원시 팔레트를 화면에서 쓰지 않는다** |
| 글자 | 16종 (`displayM` · `headingL/M/S` · `bodyL/M/S`(+Strong) · `labelL/M/S/XS` · `numericL/M`) |
| 폰트 | Pretendard (OFL — 오픈소스 고지 필요) |
| 고도 | 7종. `Elevation/Card`는 2겹 그림자 |
| 컴포넌트 | 52종 |
| 다크 모드 | 없음. 분기하지 않는다 |
| 브랜드 고정색 | 카카오 버튼 색은 테마와 분리해 상수로 둔다. 가이드가 변경을 금지한다 |

**규칙:** 임의의 수치를 쓰지 않는다. 새 값이 필요하면 토큰을 먼저 추가한다. Figma에
없거나 모호하면 구현을 멈추고 묻는다.

---

## 5. 상태·오류 규칙 (화면 공통)

| 상태 | 규칙 |
| -- | -- |
| 로딩 | 화면마다 그린다. 전역 스피너로 덮지 않는다 |
| 네트워크 없음 | 재시도 가능한 안내 |
| 서버 거절 | 서버 메시지를 그대로 보여주되 민감정보는 싣지 않는다 |
| 빈 화면 | Figma에 그려진 `EmptyState` 사용 |
| 일회성 신호 | 토스트·네비게이션 같은 일회성 신호를 상태로 들고 있지 않는다. 소비 후 되돌린다. **화면을 바꾸기 전에 소비 표시를 남긴다** — 화면이 바뀌면 뒤에 둔 코드가 실행되지 않는다 |
