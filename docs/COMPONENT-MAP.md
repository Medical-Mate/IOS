# 컴포넌트 대응표

Figma 마스터와 iOS 구현의 대응이다. **컴포넌트는 Figma 마스터를 그대로 옮긴다.** 임의로
만들거나 비슷한 것으로 대신하지 않는다.

| 항목 | 값 |
| -- | -- |
| Figma 파일 | `AX 해커톤 - 3차 프로젝트` (`OWKWtDt8lLQLmltq0ztT5O`) |
| 디자인 시스템 | `291:636` · 2026-10-15 추가분 `3610:1849` |
| 마지막 대조 | 2026-11-20 |

---

## 1. 들어온 컴포넌트 (42)

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
| KV Row · Editing | `597:4801` | `MMKVEditRow` | 브리핑 카드 편집의 항목 줄. 읽는 줄과 다른 컴포넌트다 |
| Text Field · 문답 인스턴스 | `295:692` + `631:1294` | `MMChatComposer` | 라벨·도움말을 끄고 `Actions`에 마이크·보내기를 넣은 모양(1c-2~1c-D3). 받아쓰기를 못 하는 기기에서는 마이크를 그리지 않는다 |

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
| Bottom Sheet (1e-1-X · 1e-1-S 껍데기) | `3663:7479` | `MMBottomSheet` | 손잡이 36×4 · 위 모서리 28 · `Elevation/Sheet` |
| Typing (1c-3 안쪽) | `3663:7212` | `MMTypingIndicator` | 점 셋 · `bg/primary` 0.35 · 0.6 · 1.0. 마스터에 없는 값을 만들지 않고 그 셋을 돌려 쓴다. Reduce Motion에서는 멈춘다 |

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

마스터와 컴포넌트 설명이 어긋나면 **마스터를 따랐다.** 코드 주석에도 같은 내용을 적어
두었다.

**닫힌 것 스물넷.** 남은 넷(14 · 16 · 27 · 28)은 5장에 따로 적었다. 시안이 말하지 않는 자리라도
참조 구현이 규칙이나 낱말을 이미 정해 둔 것이 있고, 수치가 양쪽 같은 것도 있다. 그래서
디자인 트랙에 묻기 전에 Android를 먼저 본다.

**넷(1 · 4 · 6 · 8)은 두 플랫폼이 갈려 있던 자리이고 안드로이드에 맞췄다.** 마스터의
기하·스타일 정의와 컴포넌트 설명이 어긋나는 곳인데, 설명도 Figma가 적어 둔 값이고
Android가 그쪽을 따랐다. **두 플랫폼이 다르게 보이는 것이 둘 다 Figma 안에 있는 값을
고르는 것보다 나쁘다**고 보고 맞췄다. **iOS에서 더 고칠 자리는 남지 않았다.** 스물넷이 닫혔고, 남은 넷은 이쪽 코드가 아니라
다른 트랙의 일이다 — 아래 5장을 본다.

> 마스터와 설명이 어긋날 때의 기본은 여전히 **마스터**다(1장). 안드로이드가 설명 쪽을
> 이미 구현해 둔 자리에서만 그쪽으로 간다 — 그때는 고르는 문제가 아니라 두 플랫폼을
> 맞추는 문제다.

| # | 자리 | 설명 | 마스터 | 택한 것 |
| -- | -- | -- | -- | -- |
| 1 | `Label/S` 굵기 | — | `Pretendard Regular 400` | **닫혔다. Medium으로 맞췄다.** 마스터의 스타일 정의는 Regular인데 컴포넌트 설명과 Android `Type.kt`가 `Medium 11/16, 자간 2.0`이다. 두 플랫폼이 갈려 있던 자리라 안드로이드에 맞췄다 |
| 2 | `Chip / Selected` | "면 + 테두리 + **체크** 셋을 겹친다" | 체크 레이어가 없다 | **닫혔다.** 면 + 1.5px 테두리이고 선택은 접근성 특성으로도 읽힌다. Android `Chip.kt`도 설명에는 체크를 적어 두었지만 **그리는 것은 글자뿐**이라 양쪽이 같다 |
| 3 | `Text Field` 반경 | 14 | 16 | **닫혔다.** 양쪽 다 16이다 — Android도 `MedicalMateRadius.md`(16)를 쓰고 "Text Field v2의 radius 16"이라고 적어 두었다. 설명의 14가 옛 값이다 |
| 4 | `KV Row` 키 폭 | 72 | 60 | **닫혔다. 72로 맞췄다.** 마스터의 기하는 60인데 설명과 Android `Rows.kt`(`KeyColumnWidth = 72`)가 72다. 키 폭을 고정하는 까닭이 값의 세로 정렬이라 두 플랫폼이 갈리면 안 된다 |
| 5 | `Dialog` 취소 버튼 | Outline | Tonal | **닫혔다.** 양쪽 다 Tonal이다 — Android `Dialog.kt`도 `MedicalMateButtonType.TONAL`을 쓴다 |
| 6 | `Tab Bar` 라벨 | 활성이면 무게가 Medium→SemiBold | 활성·비활성 모두 `Label/S` | **닫혔다. 활성만 SemiBold로 맞췄다.** Android `TabBar.kt`와 같다. 채움 전환 · 색과 함께 세 가지가 겹쳐 색만으로 구분하지 않는다 |
| 7 | `Date Cell` 크기 | 46×46 | 42×42 | **닫혔다.** 양쪽 다 42다 — Android `DateCell.kt`의 `MedicalMateDateCellSize = 42.dp`. 터치 영역은 부모 격자에서 확보한다 |
| 8 | `Callout` 질문 pill | 흰 75% 반투명 | `bg/surface`(불투명) | **닫혔다. 75%로 맞췄다.** Android `Callout.kt`의 `QUESTION_PILL_ALPHA = 0.75f`와 같다. 아래 `bg/info` 면이 비쳐 묶음 안의 줄로 읽힌다 |
| 9 | `Social Login Button` 폭 | — | 350(캔버스 390 시절) | **닫혔다.** fill-width이고 색·높이·반경은 마스터 그대로다. Android `SocialLoginButton.kt`도 `fillMaxWidth()`를 쓰고 350×56은 문서 규격으로만 적어 두었다 |
| 10 | `1j-4`의 카드 배지 | FEATURE-SPEC 2.4가 **네 가지**(작성 중 · 임시 저장 · 진료 전 · 진료 완료)를 적었다 | 세 줄 모두 기본 인스턴스 "진료 전"이다 | **닫혔다.** 데이터로 가른다. Android `RecordStatus.kt`가 같은 네 가지를 `Badge` 마스터의 변이 이름(Neutral 작성 중 · Warning 임시 저장 · Brand 진료 전 · Success 진료 완료)으로 쓰고, **시안 1j-4는 임시 저장이 생기기 전 것**이라고 적어 두었다. 문구 · 톤이 양쪽이 같다 |
| 11 | `1c-D1`과 `1c-D4`의 마무리 문장 | — | 둘째 줄이 다르다 — D1은 "더 묻고 싶은 게 있으면 빈 칸에 적어주세요", D4는 "진료실에서 순서대로 물어보세요" | **닫혔다.** 직접 적은 줄이 있는지로 가른다 — Android `IntakeQuestionRows.kt`가 같은 규칙이다. **고른 것이 아니라 줄 전체를 본다**(적어 넣고 체크를 푼 줄도 직접 적은 것이다) |
| 12 | 문답 입력 줄의 플레이스홀더 | — | `1c-2`·`1c-3`은 "메시지 입력", `1c-D2`는 빈 칸(영폭 공백) | **닫혔다.** "메시지 입력"으로 통일했고 Android도 `intake_chat_placeholder` 하나로 쓴다. D2는 커서가 선 상태를 그린 것으로 보인다 |
| 13 | `1m-B`의 `Empty State` | 마스터 variant는 넷(NoRecord · NoResult · Offline · MicDenied)이고 셋 다 액션 버튼을 들고 있다 | `search-off`를 `hospital`로 바꾸고 문구를 덮고 **액션을 껐다.** 칸 사이도 12가 아니라 10이다 | **닫혔다.** 인스턴스 그대로 따랐다(아이콘 · 문구 · 액션 없음). Android도 같은 판단이다(#228). 칸 사이만 마스터의 12를 지켰다 — 인스턴스에서 밀린 값으로 보인다 |
| 14 | `1e-1`의 `onset` 줄 이름 | Android는 축 이름을 "시작"으로 둔다(`CardMapping.kt`) | 마스터가 **"기간"**이고 값도 "3주 전 시작 · 최근 악화"다 | **마스터를 따라 "기간".** 이 자리는 Figma가 값을 들고 있으므로 28번과 같이 **Android 쪽을 디자인 트랙에 올려야 한다** |
| 15 | `1e-1`의 카드 배지 | FEATURE-SPEC 2.4의 네 가지 | 모든 상태에서 `Badge` 기본값 "작성중"이다 | **닫혔다.** 10번과 같은 자리이고 같은 근거다 — 카드는 만들 때부터 확정이라 상세에 "작성중"이 설 수 없다 |
| 16 | `KV Row` `Type=Emphasis` | "그 진료에서 가장 중요한 한 항목" | 마스터에 variant가 있고 `1e-1`의 "기간" 줄이 그것이다 | **양쪽이 같다. 둘 다 못 쓰고 있다.** Android도 `BriefCardItem.emphasized`와 `KvRowType.EMPHASIS`를 두고 "어느 항목을 세울지는 AI가 정한다"고 적었지만, 응답에 그 값이 없어 미리보기 말고는 켜지 않는다. **백엔드 대기**이고 플랫폼 사이 어긋남은 아니다 |
| 17 | `KV Row / Editing`(`597:4801`) | — | 읽는 `KV Row`(`333:1100`)와 **다른 컴포넌트**다. 키 폭 52 · 밑줄 · 지우기 | **닫혔다.** 따로 옮겼고(`MMKVEditRow`) Android도 `MedicalMateEditingKvRow`로 따로 둔다. 마스터 목록에 없던 자리라 1장 표에 더했다 |
| 18 | `1m-12`의 "다른 병원이에요" | `Button / Ghost` 인스턴스다 | **96×20으로 눌려 있다** — 세 크기(56 · 48 · 40) 어디에도 맞지 않고 좌우 여백도 없다 | **닫혔다.** 컴포넌트를 그대로 쓰고 **버튼의 좌우 여백 20만큼 왼쪽으로 물려** 글자를 콘텐츠 끝에 붙인다. 누르는 영역은 그대로다 — Android `ClinicConfirmScreen.kt`가 같은 방식이다 |
| 19 | `1p` 카드의 "오늘 진료" | — | 날짜가 오늘인 표본뿐이다 | **닫혔다.** 지난 날짜는 **"그 날 진료"**다 — Figma에 없는 말이라 비워 두었는데 Android가 `visit_note_headline_label_past`로 들고 있어 그것을 따랐다 |
| 20 | `1r-2`의 `Empty State` 액션 | 마스터는 Tonal(면 있는 버튼) | **면 없는 `fg/link` 글자**다 | **닫혔다.** 인스턴스를 따랐고(`actionStyle`) Android도 "시안의 인스턴스가 전부 채움을 지웠다"며 면 없는 글자로 그린다. **크기·반경은 마스터 그대로라 누르는 자리는 48**이다 — 양쪽이 같다 |
| 21 | `1j-3`과 `1j-3-R`의 칸 차례 | — | `1j-3`은 카드 → 기록 → 예정으로 내려가는데 `1j-3-R`(재방문 누적)은 **최신이 위**다 | **최신이 위를 택했다**(예정 → 기록 → 카드). Android가 "최신 기록이 맨 위로 가는 게 멘탈 모델"이라는 **디자인 피드백을 적어 두고** 그쪽으로 갔고, 안드로이드 레포와 맞추기로 해 따라갔다. 딸린 결과로 카드 칸의 시점 줄에서 `09.12 진료실에서 보여줌`을 뺐다 — 바로 위 기록 칸이 같은 날짜를 이미 적는다(Android #243과 같다) |
| 22 | `1s-1`의 `Setting Row` 제목 | 마스터와 설명이 모두 `Body/L`(Regular)이다 | **토글 줄 셋만 `Body/L Strong`으로 덮여 있다.** 같은 화면의 Navigation 줄은 Regular 그대로다 | **닫혔다.** 인스턴스를 따랐고(`isTitleStrong`) Android `SettingRow.kt`도 토글 줄만 `bodyLStrong`, Navigation · Value 줄은 `bodyL`이다 |
| 23 | `1s-2`의 칩 목록 | — | 갈래마다 다섯 안팎만 서 있다(복용약에 한약·피임약·수면제가 없다) | **닫혔다.** 1b(신상정보)와 같은 배열을 쓴다. 목록이 갈리면 1b에서 고른 것이 여기에 없어 저장할 때 지워진다. Android `HealthEditViewModel`도 같은 판단이다 |
| 24 | `+ 직접 추가` 칩 뒤 | — | 칩만 있고 누른 뒤가 그려져 있지 않다 | **닫혔다.** 1b의 "직접 입력" 칸과 같은 방식(입력 칸 + 추가)으로 뒀고 Android `HealthEditViewModel`도 같다 — 넣는 동시에 고른 것으로 표시하고, 같은 갈래를 다시 누르면 닫는다 |
| 25 | `1s-1`의 `Avatar` 지름 | 마스터는 44 | 프로필 카드만 **56**이고 글자도 19.09로 커져 있다 | **닫혔다.** 인스턴스를 따라 `size`를 받게 했고(기본 44) Android `Avatar.kt`도 같은 모양이다 — 그쪽은 홈 헤더가 36으로 줄어 있다고 적어 두었다 |
| 26 | `Mate Card / 화면 이동`의 둘째 줄 | — | 시안에 있는 것은 **캘린더 한 곳뿐**이다("날짜를 말하면 그 날을 열어드려요") | **닫혔다.** 캘린더만 시안대로 두고 나머지 곳은 줄을 비웠다. Android도 `voice_moved_*` 한 줄씩만 들고 둘째 줄이 없다 |
| 27 | `1e-1` 하단 버튼 | — | 세 상태가 **모양이 다르다** — 일정 잡기는 Primary(`3663:7335`), 일정 보기는 Outline(`3663:7393`), 진료 후 기록은 Tonal(`3663:7428`) | 시안대로 갈랐다. 셋을 한 모양으로 두면 "지금 할 일"의 무게가 사라진다. 어긋남이 아니라 **놓치고 있던 것**이라 적어 둔다 |
| 28 | `1m-B`의 `Search Field` 플레이스홀더 | 마스터는 "병원 이름을 적어주세요" | 인스턴스는 **비어 있다**(`3663:7302`) | **마스터를 따랐다.** Android는 시안에 없는 "병원 이름 검색"을 쓴다(`hospital_pick_search_placeholder`) — **이 자리는 Figma가 값을 들고 있으므로 Android 쪽을 디자인 트랙에 올려야 한다** |

### 아직 못 받은 에셋

~~**홈 배너 사진 다섯 장**(`2 예약 문자` ~ `5 헤이 메이트`, `1 오늘의 한 줄 · CTA=Link`).~~
→ **받았다.** Figma의 이미지 채움으로는 32×32만 닿는데, 같은 내보내기가 Android 저장소의
`res/drawable-nodpi/img_home_banner_*.jpg` 여섯 장으로 들어가 있어 그대로 가져왔다. 필터가
적용된 판본이라 흰 글자가 읽힌다.
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

---

## 5. 다른 트랙에 올릴 것

2026-11-21에 **Android 저장소의 `strings.xml` 819건을 iOS 글자와 나란히 놓고** 한 번 더
훑었다. 그때 여덟 자리가 새로 나왔다 — iOS에서 고친 것 넷(목록의 세는 말 · 삭제 확인 ·
저장 실패 · 홈 카드 줄, 모두 커밋했다), Android 트랙으로 넘길 것 셋(#30~#32), 디자인이
정할 것 하나(#29). `1r-1-S`(카드만 있는 날 시트)와 캘린더의 점 두 가지가 통째로 빠져
있던 것도 이때 찾아 올렸다.

아래는 이쪽에서 더 고칠 것이 없는 자리들이다.

### Android 저장소에 올릴 것 일곱

일곱 자리 모두 **Figma가 값을 들고 있는데 Android가 다른 말을 쓴다.** 이쪽은 시안을
따랐으니 그쪽을 맞추면 두 플랫폼이 같아진다. (이 저장소에서 고치지 않는다 —
`CLAUDE.md` 6장 4번.)

| # | 자리 | Figma | Android 지금 |
| -- | -- | -- | -- |
| 14 | 카드 `onset` 줄 이름 | **기간** | `CardMapping.kt`의 `"시작"` |
| 28 | `1m-B` 검색 칸 플레이스홀더 | **병원 이름을 적어주세요** | `hospital_pick_search_placeholder`의 `"병원 이름 검색"` |
| 30 | `1m` 둘째 줄(`3663:14329`) | **병원 이름으로 검색하면 주소가 함께 등록돼요.** | `hospital_pick_description`의 `"병원 이름으로 검색해 주세요."` |
| 31 | `1b-1` 직접 입력 플레이스홀더(`3663:6919`) | **목록에 없으면 여기에 적어주세요** | `health_edit_add_placeholder`의 `"직접 적어주세요"`. 시안에 없는 도움말(`profile_setup_other_helper`)도 한 줄 더 있다 |
| 32 | `1r-1-S` 카드 줄 둘째 줄(`3663:14570`) | **2026.09.04 작성 · 5항목** | `dayCardMeta`가 `"작성"`을 빼고 `"2026.09.04 · 5항목"`으로 적는다 |
| 34 | `1e-1-DC` 삭제 확인 본문(`3663:7690`) | **연결된 진료 기록은 남고 카드만 사라져요.** | `brief_card_delete_body`의 `"…이 카드는 사라져요."` |
| 35 | `1r-4` 저장 버튼(`3663:14772`) | **값이 비면 버튼이 꺼져 있다**(인라인 오류 글 없음) | `schedule_add_hospital_required` · `schedule_add_date_required`를 칸 아래에 적고 버튼은 켜 둔다 |

### 둘 다 시안과 다른 자리 하나

| # | 자리 | Figma | 두 플랫폼 |
| -- | -- | -- | -- |
| 33 | `1r-4-C` 할 일 빈 칸(`3663:15151`) | **밑줄 친 빈 자리**(안내 글 없음) | iOS가 `"할 일을 적어주세요"`, Android가 `"챙길 것을 적어주세요"`를 넣고 있었다. **iOS는 2026-11-21에 시안으로 되돌렸다** — 질문 빈 칸(`MMCallout`)과 같은 모양이다. Android는 그쪽 트랙이다 |

### 묻고 가야 할 자리 하나

| # | 자리 | 갈린 것 |
| -- | -- | -- |
| 29 | 병원 찾기 결과 줄의 색 | **시안 두 장이 서로 다르다.** `1m-B`(`3663:7311`)는 `fg/primary`(파랑)인데 `1m`(`3663:14329`)은 `fg/subtle`(회색)이다. 같은 상태(결과 4곳)에 다른 색이다. iOS는 결과가 있으면 `fg/primary`(= `1m-B`), Android는 언제나 `fg/subtle`(= `1m`)이다. **어느 쪽이 맞는지는 디자인이 정할 일이라 양쪽 다 그대로 두었다** |

### 백엔드에 올릴 것 하나

| # | 자리 | 막힌 것 |
| -- | -- | -- |
| 16 | `KV Row` `Type=Emphasis` | 카드 응답에 **어느 축을 세울지 가리키는 값이 없다.** Android도 `emphasized` 플래그를 만들어 두고 못 쓰고 있어 **두 플랫폼이 같이 막혀 있다** |

### 디자인 트랙에 올릴 것 하나 더

**증상 정리 1단계(`1c-1` 인체도) 화면이 와이어프레임에 없다.** D 섹션이 `1d`(2/3)부터
시작하고 디자인 시스템에도 인체도 컴포넌트가 없다. 렌더러를 무엇으로 정하든 그릴 근거가
없어서 **새로 시작하는 길이 닫혀 있다.** 좌표(`humanmap_coords.json`에서 생성) · 온톨로지 ·
2D 이미지는 Android에 다 있어 옮길 수 있다 — 필요한 것은 화면 하나다.

### 기록 하나

**27번은 어긋남이 아니다.** `1e-1` 하단 버튼이 상태마다 모양이 다른 것(Primary ·
Outline · Tonal)을 놓치고 있다가 바로잡은 자리라, 다음에 같은 것을 다시 찾지 않도록
표에 남겨 둔 것이다.
