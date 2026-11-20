# 컴포넌트 대응표

Figma 마스터와 iOS 구현의 대응이다. **컴포넌트는 Figma 마스터를 그대로 옮긴다.** 임의로
만들거나 비슷한 것으로 대신하지 않는다.

| 항목 | 값 |
| -- | -- |
| Figma 파일 | `AX 해커톤 - 3차 프로젝트` (`OWKWtDt8lLQLmltq0ztT5O`) |
| 디자인 시스템 | `291:636` · 2026-10-15 추가분 `3610:1849` |
| 마지막 대조 | 2026-11-20 |

---

## 들어온 것 (6)

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| Button | `291:670` | `MMButton` | Type 5 × Size 3 × State 3. State는 코드에서 눌림·비활성으로 갈린다 |
| Social Login Button | `383:1302` | `MMSocialLoginButton` | **브랜드 예외** — 이 컴포넌트만 토큰을 쓰지 않는다 |
| Badge | `311:834` | `MMBadge` | Tone 5 |
| Chip | `311:823` | `MMChip` | Select. Info 변형(`3610:10205`)은 `MMInfoChip` |
| Card | `293:656` | `MMCard` | Emphasis 3. Default만 `Elevation/Card` |
| Checkbox | `311:851` | `MMCheckbox` | 행 전체가 터치 영역 |

### 에셋

| Figma | 노드 | 파일 | 비고 |
| -- | -- | -- | -- |
| 카카오 로고 | `3004:18434` | `Assets.xcassets/KakaoSymbol` | 공식 로고. PDF 20×20, 벡터 보존 |
| Icon/check | `302:754` | `Assets.xcassets/icon-check` | PDF 24×24, 템플릿(색은 쓰는 쪽이 정함) |

아이콘은 24×24 격자 · 라이브 20 · 획 1.75 · 라운드 캡/조인이고 획 색이 `fg/default`에
묶여 있다. 그래서 **템플릿으로 넣고 색은 쓰는 쪽이 정한다.**

---

## 아직 안 들어온 것

마스터는 52종이다. 위 6종을 뺀 나머지는 쓰는 화면을 만들 때 같은 방법으로 가져온다.
아이콘도 `check` 하나만 들어왔고 45종이 남았다.

눈에 띄는 것만 적는다 — 전체 목록은 Figma에서 본다.

| 묶음 | 마스터 |
| -- | -- |
| 입력 | Text Field · Text Area · Radio · Toggle · Segmented Control · Search Field · Picker Field · Time Wheel |
| 목록 | List Row · KV Row · Setting Row · Todo Row · Add Row · Question Row · Step Row · Divider · Section Header |
| 내비 | Nav Bar · Tab Bar · Bottom CTA Bar · Bottom Sheet · FAB |
| 피드백 | Toast · Dialog · Notice · Callout · Tooltip · Empty State · Loading · Overlay Scrim |
| 도메인 | Severity Slider · Progress Indicator · Onboarding Progress · Bubble · Voice Input · Mate Card · Waveform · Source Quote · Doctor Card · Hospital Card · Calendar Day · Calendar Grid · Date Cell · Home Banner · Card/Action · Card/Resume · Card/Schedule · Number Badge · Export Preview |

---

## 대조하면서 발견한 것

### 1. `Label/S`의 굵기가 Android와 다르다 — **Figma를 따랐다**

Figma 스타일 정의는 `Pretendard Regular 400`이다(`Badge 311:834` · `Card 293:656` 양쪽에서
같게 보고된다). Android는 `FontWeight.Medium`으로 들고 있다. Figma가 정본이므로 iOS는
Regular로 뒀다. **디자인 트랙에 Android 쪽을 올려야 한다.**

### 2. `Chip / Selected`에 체크가 없다

Figma 설명은 "선택은 primary tint 면 + 1.5px brand 테두리 + **체크** 세 가지를 겹친다"고
적었는데 `Select / Selected` 마스터(`311:819`)에 체크 레이어가 없다. 임의로 그리지 않고
면 + 테두리 둘만 구현했다. 선택 상태는 접근성 특성(`.isSelected`)으로도 읽힌다.
**디자인 트랙 확인 필요.**

### 3. `Elevation/Card`가 코드와 정확히 맞는다

Figma가 보고한 값이 `#1B255A14 (0,3) blur 10` + `#1B255A0D (0,1) blur 2`로, M0에서 옮긴
값과 같다. Android는 이 두 겹을 한 겹으로 근사했다.

### 4. `Social Login Button`은 폭이 350이다

Figma 캔버스가 390이던 때의 값이다. 캔버스는 360으로 재단됐고(콘텐츠 320) 버튼은
fill-width라 폭을 고정하지 않았다. 색·높이·반경은 마스터 그대로다.

### 5. 네이버 버튼은 대비 기준을 넘지 못한다

`#03C75A` + 흰 글자가 2.2:1이다. 네이버 공식 규격이라 바꿀 수 없고 **이 버튼만 예외**다.
로그인 화면의 다른 안내는 반드시 기준을 넘는 색으로 둔다. 네이버·Apple·Google의 로고
자리는 Figma와 똑같이 **빈 반투명 사각**으로 뒀다 — 상표를 임의로 그리지 않는다.
쓰기 전에 각 사 공식 키트의 에셋으로 채운다.

---

## 가져오는 방법

1. Figma MCP로 세션을 연다(`create_session`, 파일 키 `OWKWtDt8lLQLmltq0ztT5O`).
2. `get_design_context`로 마스터 노드를 읽는다. **스크린샷을 함께 받아 눈으로 맞춘다.**
3. 반환된 React/Tailwind는 참고용 프로토타입이다. 토큰(`MMColor` · `MMFont` · `MMSpace` ·
   `MMRadius` · `MMElevation`)으로 바꿔 SwiftUI로 다시 쓴다. **원시 값을 박지 않는다.**
4. 아이콘·로고는 `download_assets`로 **PDF**를 받아 에셋 카탈로그에 넣는다(벡터 보존).
   SVG는 SwiftUI가 읽지 못하고, 경로를 손으로 옮겨 그리지 않는다.
5. `MMComponentGallery`에 한 줄 더하고 시뮬레이터에서 마스터와 나란히 본다.
6. `ComponentSpecTests`에 수치를 적는다.
7. 이 표에 노드 id와 함께 한 줄 더한다.

**Figma에 없거나 모호하면 멈추고 묻는다.** 비슷한 것으로 대신하거나 빈자리를 채우지 않는다.
