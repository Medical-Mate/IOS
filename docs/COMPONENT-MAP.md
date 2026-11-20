# 컴포넌트 대응표

Figma 마스터와 iOS 구현의 대응이다. **컴포넌트는 Figma 마스터를 그대로 옮긴다.** 임의로
만들거나 비슷한 것으로 대신하지 않는다.

| 항목 | 값 |
| -- | -- |
| Figma 파일 | `AX 해커톤 - 3차 프로젝트` (`OWKWtDt8lLQLmltq0ztT5O`) |
| 디자인 시스템 | `291:636` · 2026-10-15 추가분 `3610:1849` |
| 마지막 대조 | 2026-11-20 |

---

## 1. 들어온 컴포넌트 (38)

### 기본

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| Button | `291:670` | `MMButton` | Type 5 × Size 3. State는 눌림·비활성으로 갈린다 |
| Icon Button | `298:715` | `MMIconButton` | Style 4 × Size 3. 라벨이 없어 `accessibilityLabel`이 필수다 |
| Social Login Button | `383:1302` | `MMSocialLoginButton` | **브랜드 예외** — 이 컴포넌트만 토큰을 쓰지 않는다 |
| Badge | `311:834` | `MMBadge` | Tone 5 |
| Chip | `311:823` | `MMChip` · `MMInfoChip` | Select / Info(`3610:10205`) |
| Number Badge | `3644:7400` | `MMNumberBadge` | Primary · Subtle |
| Card | `293:656` | `MMCard` | Emphasis 3. Default만 `Elevation/Card` |
| Avatar | `311:839` | `MMAvatar` | Patient는 색, Doctor는 무채색 |
| Divider | `333:1088` | `MMDivider` | |
| Overlay Scrim | `335:1189` | `MMOverlayScrim` | 50% · 탭하면 닫힘 |
| Section Header | `334:1156` | `MMSectionHeader` | |

### 입력

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| Text Field | `295:692` | `MMTextField` | 상태 5 |
| Text Area | `334:1102` | `MMTextArea` | 최소 120 · 카운터 · 마이크 |
| Search Field | `590:1307` | `MMSearchField` | |
| Checkbox | `311:851` | `MMCheckbox` | 행 전체가 터치 영역 |
| Toggle | `334:1155` | `MMToggle` | 52×32 · 노브 26 |
| Time Wheel | `3645:2393` | `MMTimeWheel` | 시스템 휠을 쓰지 않는다 |

### 목록·행

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| List Row | `335:1114` | `MMListRow` | 선택 상자 · 배지 · 요약 · chevron |
| KV Row | `333:1100` | `MMKVRow` | Default · Emphasis · Link |
| Setting Row | `3645:2327` | `MMSettingRow` | Toggle · Navigation · Value |
| Question Row | `3644:7446` | `MMQuestionRow` | 상태 5 |
| Step Row | `3644:7457` | `MMStepRow` | |
| Hint Row | `3645:2369` | `MMHintRow` | |

### 내비

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| Nav Bar | `298:739` | `MMNavBar` | Glass 82% |
| Tab Bar | `319:1026` | `MMTabBar` | Glass 86% · 채움 아이콘 전환 |

### 피드백

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| Notice | `292:668` | `MMNotice` | 화면에 **남는** 안내 |
| Callout | `293:657` | `MMCallout` | 브리핑 카드에서 한 번만 |
| Dialog | `312:845` | `MMDialog` | 되돌릴 수 없는 동작의 확인 |
| Tooltip | `542:1295` | `MMTooltip` | 트리거 |
| Tooltip Bubble | `575:1287` | `MMTooltipBubble` | |
| Empty State | `335:1166` | `MMEmptyState` | 종류 4 |
| Progress Indicator | `334:1139` | `MMProgressIndicator` | 칸 수를 받는다 |
| Onboarding Progress | `1155:854` | `MMOnboardingProgress` | Reduce Motion 대응 |

### 도메인

| Figma 마스터 | 노드 | iOS | 비고 |
| -- | -- | -- | -- |
| Severity Slider | `339:1293` | `MMSeveritySlider` | 드래그 + 정지점 탭 |
| Severity Readout | `333:1126` | `MMSeverityReadout` | 출력 전용 |
| Bubble | `313:999` | `MMBubble` | AI는 면 없음 |
| Date Cell | `335:1188` | `MMDateCell` | 디자인 시스템 판 |
| Calendar Day | `3778:1867` | `MMCalendarDay` | 캘린더용. Date Cell을 대신한다 |
| Calendar Grid | `3778:1868` | `MMCalendarGrid` | 요일 줄 · 5~6주 · 범례 |
| Waveform | `3539:5606` | `MMWaveform` | L · S |
| Voice Input Mate | `3539:5647` | `MMVoiceInputMate` | |
| Mate Card | `3532:5543` | `MMMateCard` | 상태 4 |
| Home Banner | `3317:5085` | `MMHomeBanner` | 사진은 바깥에서 넣는다 |
| Link / On Image | `3313:4925` | `MMLinkOnImage` | |
| Card / Action | `3313:4946` | `MMCardAction` | **마스터가 미게시 프레임에 있다.** 게시된 `1n-2`·`1n-1`이 써서 화면에서 읽어 옮겼다 |
| Card / Schedule | `3313:4967` | `MMCardSchedule` | 위와 같다. D-day 배지는 화면의 16을 따랐다(마스터는 26) |
| Card Thumbnail | `3610:10202` | `MMCardThumbnail` | |
| Export Preview | `3610:10245` | `MMExportPreview` | |

### 에셋

| Figma | 노드 | 파일 | 비고 |
| -- | -- | -- | -- |
| Icon set | `296:4148` | `Assets.xcassets/Icons` 46종 | PDF 24×24 · 템플릿 |
| Icon/export | `3434:3096` | 같은 폴더 | 2026-10-15 추가분 |
| 카카오 로고 | `3004:18434` | `KakaoSymbol` | 공식 로고 · PDF 20×20 |
| Logo Symbol | `351:1281` | `Logo/logo-symbol-*` 5종 | 48×48 |
| Logo Lockup | `351:1303` | `Logo/logo-lockup-*` 3종 | 139×36 |
| Onboarding Illustration | `3610:10270` | `Illustration/onboarding-*` 4종 | |
| Illustration / Share Sheet | `3645:2450` | `Illustration/share-sheet` | |
| 홈 첫 배너 사진 | `3645:10804` | `Photo/home-banner-first` | 683×1024 |

아이콘은 **24×24 격자 · 라이브 20 · 획 1.75 · 라운드 캡/조인**이고 획 색이 `fg/default`에
묶여 있다. 그래서 **템플릿으로 넣고 색은 쓰는 쪽이 정한다.** 로고의 `mark` ·
`mono-light`도 단색이라 템플릿이다.

---

## 2. 일부러 옮기지 않은 것

**2026-11-20 결정: Figma 기준으로 간다.** 아래 것들은 Figma가 미사용 · 미게시로 표시해
두었으므로 옮기지 않는다. Android가 쓰는 것과 어긋나지만 **Figma가 정본이다.** 화면을
그리다 이 중 하나가 꼭 필요해지면 그때 디자인 트랙에 묻고, 답이 오기 전에는 임의로
만들지 않는다.


### 2.1 `Archive · 참고 (앱 미사용)` 15종 — **Figma가 미사용으로 못박았다**

섹션(`1864:1446`)의 첫 줄이 **"미사용 컴포넌트 15종 · 삭제하지 않고 보관"**이다.
CLAUDE.md 1장의 규칙대로 보지 않았다.

> Bottom CTA Bar · Bottom Sheet · Radio · .Toast · Voice Input · Source Quote ·
> Doctor Card · Segmented Control · Loading · Hospital Card · Picker Field ·
> Todo Row · Card Pick · Add Row · Select Bar

**⚠️ 디자인 트랙 확인 필요.** Android는 이 가운데 여럿을 화면에 쓰고 있다
(`BottomCtaBar` · `BottomSheet` · `Toast` · `Loading` · `SegmentedControl` ·
`HospitalCard` · `PickerField` · `TodoRow` · `CardPick` · `AddRow` · `SelectBar`).
Android `CLAUDE.md`는 "컴포넌트 3.0 신규 7종 모두 화면에 붙었다"고 적었고
Hospital Card는 1e-1, Picker Field·Card Pick·Add Row는 1r-4, Todo Row는 1r-2·1r-4에
쓴다고 했다. **Figma가 미사용으로 옮긴 것인지, 보관함에 중복으로 들어간 것인지
확인해야 한다.** 답이 나오기 전에는 옮기지 않는다.

### 2.2 `홈 · 신규 컴포넌트 (제안 · 미게시)` — 남은 것은 `Card / Resume` 하나

`3313:4910` 프레임 이름이 **제안 · 미게시**다. 그 가운데 **`Link / On Image` ·
`Card / Action` · `Card / Schedule` 셋은 게시된 와이어프레임(`1n-2` · `1n-1`)이
실제로 쓰고 있어** 화면에서 읽어 옮겼다. 프레임이 미게시여도 화면이 쓰면 화면이
정본이다.

남은 것은 **`Card / Resume`(이어서 하기)** 하나다. `1n-1`에 인스턴스가 없어 규격을
읽을 자리가 없다. 이어서 하기가 필요한 화면을 그릴 때 그 화면에서 읽거나, 그때까지
마스터가 게시되면 마스터에서 가져온다. **⚠️ 그 전에는 만들지 않는다.**

### 2.3 `수정 중` 2종

`Tab Bar / Briefing`(`3215:1762`) · `Icon/briefing-cards`(`3215:1569`). 미게시 작업물이다.

### 2.4 `Push Notification` (`3955:12757`)

섹션 이름이 **"시간 확정 · 미정"**이고 내용이 **안드로이드 알림 창** 모형이다. iOS 알림은
시스템이 그리므로 옮길 것이 없다. 문구와 시각 규칙만 `docs/FEATURE-SPEC.md` 2.7에 있다.

---

## 3. 대조하면서 발견한 것

마스터와 컴포넌트 설명이 어긋나면 **마스터를 따랐다.** 아래는 전부 디자인 트랙 확인이
필요한 자리이고, 코드 주석에도 같은 내용을 적어 두었다.

| # | 자리 | 설명 | 마스터 | 택한 것 |
| -- | -- | -- | -- | -- |
| 1 | `Label/S` 굵기 | — | `Pretendard Regular 400` | **Regular**. Android는 Medium이라 두 플랫폼이 갈린다 |
| 2 | `Chip / Selected` | "면 + 테두리 + **체크** 셋을 겹친다" | 체크 레이어가 없다 | 면 + 1.5px 테두리. 선택은 접근성 특성으로도 읽힌다 |
| 3 | `Text Field` 반경 | 14 | 16 | **16** |
| 4 | `KV Row` 키 폭 | 72 | 60 | **60** |
| 5 | `Dialog` 취소 버튼 | Outline | Tonal | **Tonal** |
| 6 | `Tab Bar` 라벨 | 활성이면 무게가 Medium→SemiBold | 활성·비활성 모두 `Label/S` | **마스터**. 채움 전환과 색 둘은 그대로라 색만으로 구분하지는 않는다 |
| 7 | `Date Cell` 크기 | 46×46 | 42×42 | **42**. 터치 영역은 부모 격자에서 확보 |
| 8 | `Callout` 질문 pill | 흰 75% 반투명 | `bg/surface`(불투명) | **마스터** |
| 9 | `Social Login Button` 폭 | — | 350(캔버스 390 시절) | fill-width. 색·높이·반경은 마스터 그대로 |

### 아직 못 받은 에셋

**홈 배너 사진 다섯 장**(`2 예약 문자` ~ `5 헤이 메이트`, `1 오늘의 한 줄 · CTA=Link`).
마스터의 이미지 채움으로 닿는 파일이 32×32라 사진이 아니다. 첫 홈(`CTA=None`)의 사진만
683×1024로 받아 넣었다. **디자인 트랙에서 필터(밝기 · 색온도)가 적용된 내보내기를
3배로 받아야 한다** — 원본 사진은 훨씬 밝아 그대로 쓰면 흰 글자가 읽히지 않는다.

`Social Login Button`의 네이버 · Apple · Google 로고 자리는 Figma와 똑같이 **빈 반투명
사각**으로 뒀다. 상표라 각 사 공식 키트의 에셋으로 채워야 한다. 네이버 버튼은
`#03C75A` + 흰 글자가 2.2:1로 대비 기준을 넘지 못한다 — 네이버 공식 규격이라 **이 버튼만
예외**이고, 로그인 화면의 다른 안내는 반드시 기준을 넘는 색으로 둔다.

### SwiftUI로 표현하지 못한 것

~~`Elevation/Primary`는 `.shadow`에 spread가 없어 쓰지 못한다~~ → **풀었다.**
`#3B4FC0 28% (0,8) blur 30 spread -18`을 **도형을 18 줄여 뒤에 깔고 거기에 그림자를
거는** 방식으로 냈다(`mmPrimaryElevation()`). 줄인 도형은 카드가 덮어 그림자만 남는다.
그냥 `.shadow`를 걸면 그림자가 카드보다 커져 번져 보인다.

---

## 4. 가져오는 방법

1. Figma MCP로 세션을 연다(`create_session`, 파일 키 `OWKWtDt8lLQLmltq0ztT5O`).
2. `get_design_context`로 마스터 노드를 읽는다. **스크린샷을 함께 받아 눈으로 맞춘다.**
3. 반환된 React/Tailwind는 참고용 프로토타입이다. 토큰(`MMColor` · `MMFont` · `MMSpace` ·
   `MMRadius` · `MMElevation`)으로 바꿔 SwiftUI로 다시 쓴다. **원시 값을 박지 않는다.**
4. 색을 코드에서 읽을 수 없으면 **내보낸 SVG의 `stroke`/`fill`을 확인한다.** 짐작하지
   않는다 (Icon Button · Notice · Toggle · Date Cell을 이렇게 확정했다).
5. 아이콘·로고·일러스트는 `download_assets`로 **PDF**를 받아 에셋 카탈로그에 넣는다
   (벡터 보존). SwiftUI가 SVG를 읽지 못하고, **경로를 손으로 옮겨 그리지 않는다.**
6. `MMComponentGallery`에 한 줄 더하고 시뮬레이터에서 마스터와 나란히 본다.
7. `ComponentSpecTests`에 수치를 적는다.
8. 이 표에 노드 id와 함께 한 줄 더한다.

**Figma에 없거나 모호하면 멈추고 묻는다.** 비슷한 것으로 대신하거나 빈자리를 채우지
않는다. 마스터와 설명이 어긋나면 마스터를 따르고 3장에 적는다.
