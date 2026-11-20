# AOS ↔ iOS 구현 차이

| 항목 | 값 |
| -- | -- |
| 문서 판 | v1.0 (2026-11-20) |
| 목적 | Android 구현을 iOS로 옮길 때 **무엇이 그대로 되고, 무엇이 대체되고, 무엇이 안 되는지**를 먼저 정한다 |
| 기준 | `Medical-Mate/Android` main 소스에서 실제로 쓰는 플랫폼 API를 전수 조사해 작성 |

---

## 0. 한눈에

| 등급 | 뜻 | 건수 |
| -- | -- | -- |
| 🟢 **동등** | 개념이 1:1로 대응한다. 번역만 하면 된다 | 9 |
| 🟡 **대체** | iOS 대안이 있으나 동작·제약이 달라 설계가 바뀐다 | 8 |
| 🔴 **결정 필요** | iOS에 같은 수단이 없다. 기능을 바꾸거나 포기하는 결정이 필요하다 | 4 |

🔴 네 건: **온디바이스 LLM**, **호출어 상시 청취**, **문자 공유 수신**, **Sign in with Apple(심사)**.
이 넷은 코드를 쓰기 전에 결정해야 한다.

---

## 1. 기반 기술 대응표

| 영역 | Android | iOS | 등급 | 메모 |
| -- | -- | -- | -- | -- |
| 언어 | Kotlin 2.2 | Swift 6 | 🟢 | |
| UI | Jetpack Compose + Material 3 | SwiftUI | 🟢 | 둘 다 선언형. M3 컴포넌트는 안 쓰고 자체 디자인 시스템이라 이식이 오히려 쉽다 |
| 아키텍처 | MVVM 단방향 + Hilt | MVVM + `@Observable` + 수동 DI 또는 swift-dependencies | 🟢 | Hilt 같은 컴파일타임 DI가 iOS에 없다. 생성자 주입 + Environment로 충분 |
| 네비게이션 | Navigation Compose 단일 `NavHost`, 타입 세이프 라우트 | `NavigationStack` + `NavigationPath`, `Hashable` 라우트 enum | 🟢 | **단일 스택 유지.** 로그인/본문으로 스택을 쪼개지 말고 루트까지 pop으로 경계를 넘는다 |
| 화면 상태 수명 | 목적지 스코프 ViewModel | `@State`가 뷰 수명에 묶임 | 🟡 | Android는 pop될 때 ViewModel이 파기된다. SwiftUI는 뷰가 스택에서 빠질 때 `@State`가 사라지므로 **대체로 동등하나**, 로그아웃 시 잔존 상태를 직접 확인해야 한다 |
| 네트워크 | Retrofit 3 + OkHttp 5 | `URLSession` + 얇은 클라이언트 | 🟢 | Alamofire 불필요 |
| 직렬화 | kotlinx.serialization | `Codable` | 🟢 | |
| 결과 타입 | `ApiResult`(Success/Rejected/NetworkUnavailable) | 같은 모양의 Swift enum | 🟢 | **`try/catch`로 되돌리지 않는다.** 계층을 넘는 예외는 호출자가 무엇이 오는지 모른다 |
| 401 재발급 | OkHttp `Authenticator` + `@AuthFree` 별도 클라이언트 | `URLSession` 재시도 래퍼 + 인증 안 붙는 별도 세션 | 🟡 | iOS엔 `Authenticator` 대응이 없다. 직접 만들되 **동시 401이 여러 개여도 재발급은 한 번만** 하도록 직렬화해야 한다 |
| 키-값 저장 | DataStore Preferences | `UserDefaults` | 🟢 | |
| 토큰 저장 | DataStore(평문) + `allowBackup=false` | **Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | 🟡 | **iOS가 더 낫다.** Android의 미해결 과제(평문 저장)를 iOS에서는 처음부터 피한다 |
| 백그라운드 작업 | WorkManager | `BGTaskScheduler` / `URLSession` 백그라운드 | 🟡 | iOS는 실행 시점을 보장하지 않는다. 알림은 WorkManager가 아니라 로컬 알림 스케줄로 해결한다(3.4) |
| 빌드 | Gradle 9.5 | Xcode + SwiftPM | 🟢 | |
| 품질 게이트 | ktlint · detekt · Android Lint · JUnit | SwiftLint · SwiftFormat · Swift Testing | 🟢 | CI에서 똑같이 강제한다 |

---

## 2. 디자인 시스템 이식

| 항목 | Android | iOS | 메모 |
| -- | -- | -- | -- |
| 단위 | `dp` / `sp` | `pt` | 1dp ≈ 1pt. 수치를 그대로 쓴다 |
| 색 토큰 | `CompositionLocal`로 내려주는 `MedicalMateColors` 44종 | `Color` 확장 또는 Asset Catalog + Environment | 다크 값이 없으므로 **Asset Catalog에 Any Appearance 하나만 넣는다** |
| 글자 | `TextStyle` 16종, Pretendard | `Font` 확장 16종, Pretendard 번들 | `UIFontDescriptor`로 Dynamic Type 대응 여부는 결정 필요 |
| 간격·크기·반경 | `object MedicalMateSpace/Size/Radius` | `enum MMSpace/MMSize/MMRadius` | 테마에 따라 안 변하므로 Environment 불필요 |
| 터치 최소 | 48dp | **44pt** (HIG) | 48pt로 그대로 둘지 44로 줄일지 디자인 트랙 확인 필요 |
| 그림자 | `Modifier.shadow` / `dropShadow` 2겹 | `.shadow()` 중첩 | Figma `Elevation/Card`는 2겹(y3 r10 8% + y1 r2 5%). **Android는 1겹 근사라 iOS가 더 정확히 맞출 수 있다** |
| 블러(Glass) | `RenderEffect` (API 31+). minSdk 26이라 8.0~11에 안 걸려 Opaque 대안 필수 | `.ultraThinMaterial` 등이 iOS 15부터 전부 동작 | **iOS는 Opaque 대안이 필요 없다.** 다만 Figma 값과 재질이 다르므로 대조 필요 |
| 다크 모드 | `values-night` 금지 | `.preferredColorScheme(.light)` 고정 | 시스템 다크에서 색이 뒤집히지 않도록 명시 고정 |
| 애니메이션 끄기 | 시스템 설정 확인 | `@Environment(\.accessibilityReduceMotion)` | 홈 배너 자동 전환에 필요 |
| 접근성 | `semantics`, `Role.RadioButton` | `.accessibilityLabel/.accessibilityAddTraits` | 부위 목록은 라디오 역할을 실어 "선택됨"이 읽히게 한다 |
| 아이콘 | 벡터 drawable (Figma 내보내기) | SVG → PDF/Asset Catalog 또는 SF Symbols 금지 | **SF Symbols로 대체하지 않는다.** Figma 자산을 그대로 쓴다 |

---

## 3. 기능별 차이 (상세)

### 3.1 🔴 3D 인체도 — 렌더러 교체

| | Android | iOS 후보 |
| -- | -- | -- |
| 렌더러 | **Filament** (`filament-android` + `gltfio-android`), `TextureView` + `Choreographer` 수동 프레임 루프 | ① **SceneKit** — 가장 적은 코드, glTF 미지원이라 USDZ/SCN 변환 필요<br>② **RealityKit** — USDZ 네이티브, iOS 18+ 비AR 렌더 가능하나 제어가 거칠다<br>③ **Metal + 직접 glTF 로더** — 자산 그대로, 비용 최대<br>④ **Filament iOS** (공식 지원) — **자산·좌표·카메라 코드를 그대로 쓸 수 있다** |
| 자산 | `body.glb`, `body_bx05.glb` (Draco 압축), `body_collision.bin` | Filament iOS면 그대로. SceneKit/RealityKit이면 **USDZ 변환 파이프라인을 디자인/AI 트랙과 합의해야 한다** |
| 좌표 | `BodyMap3dGeometry.kt` — `anchors3d.json`에서 **생성된 파일**. 손으로 고치지 않는다 | 같은 `anchors3d.json`에서 Swift 파일을 생성한다. **생성 스크립트를 iOS 레포에 둔다** |
| 피킹 | 충돌 메시(`body_collision.bin`)로 레이캐스트 | 동일 메시 + 렌더러별 레이캐스트 API |

**권고:** Filament iOS를 1순위로 검토한다. 좌표표·충돌 메시·카메라 로직이 그대로 살아
포팅 위험이 가장 작다. 안 되면 M2까지는 **2D 인체도로 간다** — Android에 2D 구현과
`humanmap_coords.json`(schema 3.0) 좌표표가 남아 있고 선택 결과 값이 3D와 같다.

> 미해결(양 플랫폼 공통): 좌표표의 `SUR:041 허리 가운데`가 천골 위치(신장 58%)에 있다.
> 디자인 트랙에 수정 요청이 가 있다. **데이터만 고치면 되고 코드는 안 고친다.**

### 3.2 🟡 음성 받아쓰기 (STT)

| | Android | iOS |
| -- | -- | -- |
| 엔진 | **ML Kit GenAI SpeechRecognition** (AICore). 기기 안에서 돌고 오디오가 나가지 않는다 | `SFSpeechRecognizer` |
| 기기 내 보장 | AICore 전제 | **`requiresOnDeviceRecognition = true`를 반드시 켠다.** 끄면 Apple 서버로 오디오가 간다 — 제품 약속("오디오가 기기 밖으로 나가지 않는다") 위반 |
| 지원 기기 | API 31+ 이면서 AICore 가능. 안 되면 **마이크를 그리지 않는다** | `supportsOnDeviceRecognition`을 확인하고 같은 규칙을 적용한다 |
| 권한 | `RECORD_AUDIO` | `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` **둘 다** |
| 부분 결과 | 스트림 | `shouldReportPartialResults = true` |
| 침묵 자동 전송 | 1초 무음이면 전송, 5초 무음이면 패널 닫기 | **앱이 직접 타이머로 구현한다.** `SFSpeechRecognizer`의 자동 종료에 맡기지 않는다 — 종료 시점이 다르다 |

**주의:** `SFSpeechRecognizer`는 연속 인식에 약 1분 제한이 있다. 문답 한 턴은 짧아
문제없지만 **진료 후 메모(1p)는 길어질 수 있다.** 세션 재시작 + 텍스트 이어붙이기를
설계에 넣는다. Android에는 없는 제약이다.

### 3.3 🔴 호출어 ("헤이 메이트")

| | Android | iOS |
| -- | -- | -- |
| 엔진 | **Vosk** 영어 소형 모델(Apache 2.0), `AudioRecord`로 직접 마이크를 잡고 `NoiseSuppressor`·`AutomaticGainControl` 적용 | — |
| 모델 | `vosk-model-small-en-us-0.15`를 런타임에 내려받아 저장 | 같은 모델을 쓰려면 Vosk iOS(`libvosk`) 빌드가 필요하다 |

**iOS 선택지:**

| 안 | 내용 | 평가 |
| -- | -- | -- |
| A | **Vosk iOS 포팅** — 같은 모델, 같은 규칙 | 가능하지만 C 라이브러리 빌드 + 바이너리 용량. 앱 포그라운드 한정 |
| B | `SFSpeechRecognizer`로 상시 듣고 문자열 매칭 | 1분 제한·배터리·온디바이스 보장 문제로 부적합 |
| C | **기능 축소** — 호출어를 빼고 홈/화면의 마이크 버튼으로만 음성 패널을 연다 | 가장 현실적. 제품 가치 손실이 작다 |
| D | SiriKit / App Intents — "진료메이트로 증상 정리" | iOS다운 해법. 앱 내 상시 청취가 아니라 **시스템 Siri 경유**다. 화면 이동 명령은 App Intents로 상당 부분 대체 가능 |

**권고:** **C + D.** 앱 안에서 상시 마이크를 켜는 것은 iOS에서 배터리·권한·심사 모두
불리하다. "헤이 메이트"는 M5로 미루고, 화면 이동은 App Intents / Siri Shortcuts로 낸다.
이 결정은 제품 트랙 승인이 필요하다.

### 3.4 🟡 알림

| | Android | iOS |
| -- | -- | -- |
| 수단 | **WorkManager** 로 깨워서 `NotificationCompat`로 띄움 | `UNUserNotificationCenter` + `UNCalendarNotificationTrigger` |
| 차이 | Worker가 돌아야 알림이 뜬다 | **스케줄만 걸면 시스템이 띄운다. Worker가 필요 없다** |
| 제약 | Doze·배터리 최적화 | **보류 알림 64개 상한.** 일정이 많으면 가까운 것부터 64개만 걸고 앱 실행마다 재조정해야 한다 |
| 권한 | `POST_NOTIFICATIONS` (API 33+) | `requestAuthorization` |
| 취소 | Work 취소 | 식별자로 `removePendingNotificationRequests` |

**iOS가 더 단순하다.** 다만 64개 상한 재조정 로직은 Android에 없던 새 코드다.

### 3.5 🔴 예약 문자 가져오기

| | Android | iOS |
| -- | -- | -- |
| 수단 | 매니페스트의 `ACTION_SEND` / `text/plain` **인텐트 필터**. 문자 앱 공유 메뉴에 앱이 뜬다 | **Share Extension 타깃을 따로 만들어야 한다** |
| 데이터 전달 | 인텐트 extras | App Group + `UserDefaults`/파일, 또는 커스텀 URL 스킴으로 호스트 앱 열기 |
| 텍스트 파싱 | **ML Kit Entity Extraction** 으로 날짜·시각 추출 | `NSDataDetector` (`.date`) — iOS 기본 제공, 추가 의존성 없음 |

**비용:** Share Extension은 별도 타깃·별도 서명·App Group 설정이 필요하다. 기능 자체는
구현 가능하지만 M4 이전에 잡지 않는다.

### 3.6 🔴 온디바이스 LLM

| | Android | iOS |
| -- | -- | -- |
| 엔진 | **llama.cpp** (`libllama.so` + `libggml*.so`)를 NDK로 링크. `cpp/ondevice.cpp`가 JNI 다리 | llama.cpp는 iOS 빌드를 공식 지원한다 (Metal 백엔드) |
| 모델 | Qwen3.5-2B 계열, **약 1.24GB** 런타임 다운로드 | 같은 GGUF를 쓸 수 있다 |
| 가속 | NPU 필요. **CPU로 돌면 첫 호출이 10배 느리고 5분 내 발열로 무너진다**(AI 트랙 실측) | Metal / ANE. A17 Pro 이상 등 **지원 기기 판정 기준을 새로 정해야 한다** |
| 켜는 자리 | 내 정보 토글. 켜면 모델을 받고, 받다 실패하면 다시 꺼진다. 꺼도 모델은 남기고 삭제는 따로 | 동일 규칙 유지 |
| 쓰는 곳 | 진료 후 메모 분류, 진료 전 문답 추출·질문 후보 | 동일 |
| 제약 | — | **다운로드는 `URLSession` 백그라운드 전송으로, 셀룰러는 막는다.** 앱 번들에 모델을 넣지 않는다(App Store 용량) |

**선택지:** ① llama.cpp를 XCFramework로 빌드해 그대로 포팅 ② Core ML 변환
(MLX/`coremltools`) ③ **iOS 1차 출시에서는 기능 제외하고 서버 처리만 쓴다**.

**권고:** M5까지 ③으로 간다. 기능이 토글이고 꺼진 상태가 정상 동작이므로 **제품 흐름이
깨지지 않는다.** 토글 자체를 iOS에서 그리지 않으면 된다(Android도 "안 되는 기기에서는
토글을 그리지 않는다"가 이미 규칙이다).

### 3.7 🟡 카카오 로그인

| | Android | iOS |
| -- | -- | -- |
| SDK | `com.kakao.sdk:v2-user` 2.25.0 (Maven Central에 없어 카카오 전용 저장소 등록) | **Kakao iOS SDK** — SwiftPM/CocoaPods 지원 |
| 앱 전환 | `<queries>`로 카카오톡 패키지 조회 (SDK가 선언, 손으로 넣지 않음) | **`LSApplicationQueriesSchemes`에 `kakaokompasauth`·`kakaolink` 등을 직접 넣어야 한다** |
| 콜백 | `AuthCodeHandlerActivity` + `kakao{앱키}://oauth` 인텐트 필터 | URL 스킴 `kakao{앱키}` + `onOpenURL` |
| 키 보관 | `local.properties`의 `KAKAO_NATIVE_APP_KEY`, 없으면 빈 문자열로 빌드 통과 | `.xcconfig` + `Info.plist` 치환. **키를 커밋하지 않는다** |
| Activity Context | ViewModel에 `Context`를 넣지 않고 UI 계층이 SDK를 부른다 | iOS는 `UIApplication` 접근이 쉬워 제약이 덜하지만 **같은 경계를 지킨다** — 모델이 UIKit을 모르게 둔다 |

**추가:** 🔴 **Sign in with Apple.** 소셜 로그인을 제공하면 App Store 심사 지침 4.8이
적용될 수 있다. 백엔드 `User`가 `kakaoId` 단독이라 **스키마 변경이 필요하다.** 출시 전
백엔드 트랙과 결정해야 한다. 코드를 쓰기 전에 답이 나오는 편이 좋다.

### 3.8 🟡 카드 이미지 저장 · 공유

| | Android | iOS |
| -- | -- | -- |
| 캡처 | Compose → `Bitmap` | `ImageRenderer` (SwiftUI, iOS 16+) |
| 저장 | `MediaStore` + `ContentValues`, 구버전은 `WRITE_EXTERNAL_STORAGE` + `MediaScannerConnection` | `PHPhotoLibrary` + `NSPhotoLibraryAddUsageDescription` |
| 공유 | `FileProvider` + `ACTION_SEND` | `ShareLink` / `UIActivityViewController` |

iOS가 더 짧다.

### 3.9 🟡 시스템 캘린더 일정 추가

Android는 `CalendarContract.ACTION_INSERT` 인텐트로 기본 캘린더 앱을 연다. iOS는
`EKEventEditViewController`를 띄우거나 `EventKit` 쓰기 권한(`NSCalendarsWriteOnlyAccessUsageDescription`,
iOS 17+)을 받는다. **앱 내부 캘린더는 서버 데이터이고 이것은 기기 캘린더로 내보내는
별개 기능이다.** 혼동하지 않는다.

### 3.10 🟢 홈 배너 순환

4초마다 0.5초 전환, 끝에서 첫 장으로 이어짐, 손으로 넘기는 동안은 세지 않음,
**시스템이 애니메이션을 껐으면 자동 전환 안 함**. SwiftUI `TabView(.page)` + `Timer` +
`accessibilityReduceMotion`으로 그대로 구현된다.

사진 위 흰 글자의 2겹 그림자는 Android가 "텍스트를 두 번 겹쳐 그려" 냈다
(`TextStyle`이 그림자를 한 겹만 받아서). **SwiftUI는 `.shadow()`를 중첩할 수 있어 겹쳐
그릴 필요가 없다.**

---

## 4. 제품 사양이 달라져야 하는 것 (결정 목록)

| # | 항목 | Android | iOS 제안 | 승인 필요 |
| -- | -- | -- | -- | -- |
| D1 | 호출어 상시 청취 | 있음 (Vosk) | **보류**, 마이크 버튼 + App Intents로 대체 | 제품 |
| D2 | 온디바이스 LLM | 있음 (llama.cpp, 1.24GB) | **1차 출시 제외**, 서버 처리만 | 제품 · AI |
| D3 | Sign in with Apple | 없음 | **추가 필요** (심사 리스크) | 제품 · 백엔드 |
| D4 | 예약 문자 가져오기 | 인텐트 필터 | Share Extension (M4) | 제품 |
| D5 | 3D 인체도 | Filament | Filament iOS 우선, 아니면 2D 선행 | 디자인 · AI |
| D6 | 최소 터치 영역 | 48dp | 44pt (HIG) 또는 48 유지 | 디자인 |
| D7 | 최소 OS | minSdk 26 | **iOS 17.0 확정 (2026-11-20)** | ~~앱~~ 완료 |
| D8 | Dynamic Type | 해당 없음 | 대응 범위 결정 | 디자인 |

---

## 5. iOS가 Android보다 **나은** 자리

포팅을 "손해"로만 보지 않기 위해 적는다.

1. **토큰 저장** — Android는 DataStore 평문이 미해결 과제다. iOS는 Keychain으로 처음부터 해결한다.
2. **2겹 그림자** — Android는 1겹 근사. iOS는 Figma 값을 그대로 낸다.
3. **블러(Glass)** — Android는 API 31 미만에 Opaque 대안이 필요하다. iOS는 전 기기 동작.
4. **알림** — WorkManager 없이 시스템 스케줄로 끝난다.
5. **사진 저장 · 공유** — `ImageRenderer` + `ShareLink`로 코드가 크게 준다.
6. **날짜 파싱** — ML Kit Entity Extraction 대신 `NSDataDetector`로 의존성이 하나 준다.
7. **탈퇴 후 재가입 온보딩 중복** — Android의 알려진 결함. iOS는 처음부터 서버 `onboardingCompleted`를 정본으로 삼아 피한다.
8. **질문 상한 초과 거절 무시** — Android가 `PUT /questions` 거절 결과를 버린다. iOS는 화면에 알린다.

---

## 6. 포팅할 때 반드시 가져와야 하는 **규칙** (코드가 아니라 판단)

Android 코드에 주석으로 남아 있는 결정들이다. 다시 발견하지 말고 그대로 지킨다.

1. 세션은 **강도 다음에서 연다.** 부위만 고르고는 열지 않는다.
2. 부위를 바꾸면 세션을 버리고 새로 연다. 강도만 바꾸면 `PUT severity`.
3. 질문 상한 5는 **한 곳에 상수로** 두고 문답과 카드 편집이 함께 쓴다.
4. 환자가 질문을 한 번이라도 손댔으면 서버 후보로 덮지 않는다.
5. 재방문 날짜로 **일정을 자동 생성하지 않는다.** 환자가 보고 정한다.
6. 진료 후 기록은 **필수 입력이 없다.**
7. 카드를 지워도 기록은 남고, 줄 제목은 기록에 박아둔 값으로 그린다.
8. "진료 완료" 판단은 `visited`로 한다. 병원명으로 하지 않는다.
9. 일정 수정의 `nil`은 "안 바꿈", `[]`는 "전부 뗌". 시각 비우기는 별도 플래그.
10. 일정 출처는 모르는 값이면 `MANUAL`로 본다.
11. 할 일 줄의 key는 앱이 만든다. 글을 key로 쓰지 않는다.
12. 건강 정보가 비어 있는 것을 "없다"로 보지 않는다 → `UNKNOWN`.
13. 부위 선택 상태는 `focus`와 `selection`을 분리한다.
14. 부위 이름의 조사를 문자열에 박지 않는다 (부위 25종, "무릎가"가 된다). 조사는 코드가 고른다.
15. 생성된 좌표 파일(`BodyMap*Geometry`)은 손으로 고치지 않는다. 원본 JSON에서 다시 만든다.
16. API 실패는 값으로 다룬다. 직렬화 실패는 잡지 않는다.
17. 재발급 호출은 인증을 붙이지 않는 별도 클라이언트로 나간다.
18. 일회성 신호는 화면을 바꾸기 **전에** 소비 표시를 남긴다.
19. 카카오 브랜드 색은 테마에서 분리한다.
20. Figma에 없거나 모호하면 **멈추고 묻는다.** 비슷한 것으로 대신하지 않는다.
