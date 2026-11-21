# 진료메이트 (Medical Mate) — iOS

진료실에서 하고 싶은 말을 미리 정리하는 앱입니다. 환자가 아픈 부위를 짚고 AI와 문답으로
증상을 정리하면 한 장의 **브리핑 카드**가 만들어지고, 그 카드를 진료실에서 의사에게
보여줍니다. 진료가 끝나면 들은 말을 메모로 남기고, AI가 소견·검사·약·재방문으로 나눠
기록해 둡니다. 재방문 날짜는 캘린더 일정으로 이어집니다.

이 저장소는 **iOS 트랙**입니다. 같은 제품의 Android 앱이
[`Medical-Mate/Android`](https://github.com/Medical-Mate/Android)에 먼저 구현되어 있고,
백엔드와 AI, 디자인은 공용입니다.

## 지금 상태

**M0 완료.** 앱이 빌드되고 시뮬레이터에서 뜹니다. 카카오 SDK는 아직 연결하지
않았습니다. 화면은 Figma 마스터를 대조하면서 한 장씩 올리는 중입니다 — 진입과 홈,
브리핑 카드 목록과 상세, 증상 정리 2 · 3단계, 병원 찾기가 섰습니다.

```bash
xcodebuild test -project MedicalMate.xcodeproj -scheme MedicalMate -destination 'platform=iOS Simulator,name=iPhone 17'
```

M0에서 들어온 것:

| 묶음 | 내용 |
| -- | -- |
| 프로젝트 | `MedicalMate.xcodeproj` · iOS 17.0 · Swift 6 · iPhone 세로 전용 |
| 디자인 토큰 | 색 44종(+severity 10 · 캘린더 점 3) · 글자 16종 · 간격 · 크기 · 반경 · 고도 · Glass. **Figma 값 그대로** |
| 컴포넌트 | 42종 · 아이콘 47종 · 로고 8 · 일러스트 5 |
| 폰트 | Pretendard 4종 번들 (OFL) |
| 네트워크 | `ApiResult` 세 갈래 · 401 자동 재발급 · 재발급 직렬화 |
| 저장 | Keychain(`ThisDeviceOnly`)에 서버 JWT |
| 인증 | 카카오 → 서버 토큰 교환 · 로그아웃 · 회원탈퇴 흐름 |
| 네비게이션 | 단일 `NavigationStack` · 타입 세이프 라우트 · 탭 셋 |
| 화면 | 진입 10장 + 홈 2장 + 브리핑 카드 목록 4장 + 증상 정리 9장 + 병원 찾기 2장 + 브리핑 카드 11장 + 진료 후 10장 + 캘린더 월 1장 + 일정 추가 6장 + 일자 상세 6장 + 기록 목록 5장 + 기록 상세 3장 + 내 정보 3장 + 메이트 3상태 |
| 받아쓰기 | 온디바이스 고정. 못 하는 기기에서는 마이크를 그리지 않습니다 |
| 테스트 | 202건 |
| CI | SwiftLint + 빌드 · 테스트 |

**디자인 시스템이 Figma 마스터에서 전부 들어왔습니다** — 컴포넌트 42종, 아이콘 47종,
로고 8종, 일러스트 5종. 게시된 마스터는 남김없이 옮겼고, `Archive`(미사용 15종)와
미게시 작업물은 Figma가 그렇게 표시해 두어 일부러 옮기지 않았습니다. 목록 · 노드 id ·
대조하면서 발견한 어긋남 26건은 [`docs/COMPONENT-MAP.md`](docs/COMPONENT-MAP.md)에
있습니다.

## 문서

| 문서 | 내용 |
| -- | -- |
| [`docs/PRD.md`](docs/PRD.md) | 제품 요구. 문제 · 타깃 · 범위 · 성공 지표 · 마일스톤 · 열린 질문 |
| [`docs/FEATURE-SPEC.md`](docs/FEATURE-SPEC.md) | 기능명세. 화면 23개, API 28개, 도메인 모델, 상태 규칙, 디자인 토큰 |
| [`docs/AOS-IOS-DIFF.md`](docs/AOS-IOS-DIFF.md) | **AOS ↔ iOS 구현 차이.** 기술 대응표, 결정이 필요한 4건, 포팅할 때 가져와야 하는 규칙 20개 |
| [`docs/COMPONENT-MAP.md`](docs/COMPONENT-MAP.md) | Figma 마스터 ↔ iOS 컴포넌트 대응표, 가져오는 절차 |
| [`CLAUDE.md`](CLAUDE.md) | 이 저장소에서 작업할 때의 규칙 |

## 무엇을 만드는가

| 흐름 | 화면 |
| -- | -- |
| 진입 | 스플래시 · 카카오 로그인 · 온보딩 4장 · 신상정보 3단계 |
| 증상 정리 | 3D 인체도 부위 선택 → 통증 강도 → AI 문답 → 의사에게 물어볼 질문(최대 5) |
| 브리핑 카드 | 카드 읽기 · 전체 편집 · 진료받을 병원 지정 · 목록 · 삭제 · 이미지 저장 |
| 진료 후 기록 | 병원 확인 → 메모(글·음성) → AI 분류 결과 확인 → 저장 |
| 기록 | 월별 목록 · 상세 타임라인(예정 · 진료 후 기록 · 카드) |
| 캘린더 | 월 화면 · 일자 화면 · 일정 추가/수정 · 진료 전 할 일 · 다음 일정 |
| 홈 | 상황별 배너 · 이어서 하기 · 최근 브리핑 카드 · 다가오는 일정 |
| 내 정보 | 건강 정보 요약과 수정 · 알림 설정 · 로그아웃 · 회원탈퇴 |

AI 처리(문답 · 질문 추천 · 메모 분류)는 백엔드 API가 맡습니다. 기기 안에서 도는 것은
음성 받아쓰기이고 **오디오는 기기 밖으로 나가지 않습니다.**

## 아직 답이 필요한 것

[`docs/AOS-IOS-DIFF.md`](docs/AOS-IOS-DIFF.md) 4장의 결정 목록 가운데 아래 셋이 남아
있습니다. M1을 넘기기 전에 정해야 합니다.

1. **Sign in with Apple** — 소셜 로그인만 제공하면 App Store 심사 지침 4.8이 걸립니다.
   백엔드 `User` 식별자가 `kakaoId` 단독이라 스키마 변경이 필요합니다.
2. **3D 인체도 렌더러** — Android는 Filament입니다. Filament iOS를 쓰면 좌표와 자산을
   그대로 가져올 수 있고, SceneKit/RealityKit이면 USDZ 변환 파이프라인이 필요합니다.
3. **호출어 · 온디바이스 LLM** — iOS에서 그대로 하기 어렵습니다. 1차 출시 제외를
   제안합니다. 둘 다 토글이고 꺼진 상태가 정상이라 제품 흐름이 깨지지 않습니다.

## 기술 스택 (제안)

- Swift 6 · SwiftUI · `NavigationStack` 단일 스택 · 타입 세이프 라우트
- MVVM 단방향 흐름, `@Observable`, 생성자 주입
- `URLSession` + `Codable`, 실패는 예외가 아니라 결과 값(`ApiResult`)
- Keychain(토큰) · `UserDefaults`(기기 설정)
- `UNUserNotificationCenter`(로컬 알림) · `SFSpeechRecognizer`(온디바이스 받아쓰기)
- Kakao iOS SDK
- SwiftLint · SwiftFormat · Swift Testing — CI에서 강제

최소 iOS 버전은 **17.0**입니다(2026-11-20 확정).

### 로컬 설정

카카오 앱 키와 백엔드 주소는 빌드 설정에서 들어옵니다. 비밀 값은 커밋하지 않습니다.

```bash
cp Config/Example.xcconfig Config/Secrets.xcconfig
```

`Config/Secrets.xcconfig`가 없어도 빌드는 통과합니다. 실패는 카카오 API를 부를 때만 납니다.

## 함께 쓰는 저장소

[`Medical-Mate/Android`](https://github.com/Medical-Mate/Android) ·
[`Medical-Mate/Backend`](https://github.com/Medical-Mate/Backend) ·
[`Medical-Mate/AI`](https://github.com/Medical-Mate/AI) ·
[`Medical-Mate/Design`](https://github.com/Medical-Mate/Design)
