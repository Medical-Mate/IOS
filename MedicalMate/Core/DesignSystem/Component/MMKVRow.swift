import SwiftUI

/// 디자인 시스템 `KV Row` (Figma `333:1100`).
///
/// Figma 설명 그대로:
/// > 브리핑 카드의 항목 행. **키 고정 + 값 FILL. 키 폭을 고정하는 이유: 값이 세로로
/// > 정렬돼야 의사가 훑어 읽는다. 키가 길면 줄바꿈시키고 폭은 늘리지 않는다.**
/// > `Type=Emphasis`는 **그 진료에서 가장 중요한 한 항목에만. 카드마다 하나를 넘기지
/// > 않는다** — 전부 강조하면 아무것도 강조되지 않는다. `Type=Link`는 눌러서 원문이나
/// > 상세로 들어가는 행이다.
///
/// 키 폭은 **72**다. 마스터의 기하는 60인데 컴포넌트 설명과 Android `Rows.kt`가 72라서
/// 두 플랫폼이 갈려 있었고, 안드로이드에 맞췄다(COMPONENT-MAP 3장 #4).
struct MMKVRow: View {
    enum Kind { case `default`, emphasis, link }

    let key: String
    let value: String
    var kind: Kind = .default
    var action: (() -> Void)?

    var body: some View {
        if kind == .link, let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: MMSpace.s16) {
            Text(key)
                .mmTextStyle(MMFont.bodyM)
                .foregroundStyle(MMColor.fgSubtle)
                .frame(width: KVRowMetrics.keyWidth, alignment: .leading)

            Text(value)
                .mmTextStyle(kind == .emphasis ? MMFont.bodyLStrong : MMFont.bodyL)
                .foregroundStyle(kind == .emphasis ? MMColor.fgPrimary : MMColor.fgDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            if kind == .link {
                MMIcon.chevronRight.view(size: MMSize.iconMd)
                    .foregroundStyle(MMColor.fgDefault)
            }
        }
        .padding(.vertical, MMSpace.s14)
    }
}

/// 테스트가 읽는 `KV Row`의 수치.
enum MMKVRowSpec {
    static let keyWidth = KVRowMetrics.keyWidth
}

private enum KVRowMetrics {
    static let keyWidth: CGFloat = 72
}

/// 디자인 시스템 `Avatar` (Figma `311:839`).
///
/// Figma 설명 그대로:
/// > 44 원형. **Patient는 primary tint, Doctor는 무채색. 환자가 색을 갖는 규칙이
/// > 아바타에도 적용된다 — 화면의 주인공은 환자다.**
struct MMAvatar: View {
    enum Kind { case patient, doctor }

    /// 한 글자. 이름의 끝 글자나 "나"를 넣는다.
    let initial: String
    var kind: Kind = .patient
    /// 지름. 마스터는 44이고 **1s-1의 프로필만 56이다.** 글자도 같은 비율로 커진다.
    var size: CGFloat = AvatarMetrics.size

    var body: some View {
        Text(initial)
            .font(.pretendard(.semibold, size: MMFont.bodyMStrong.size * size / AvatarMetrics.size))
            .foregroundStyle(kind == .patient ? MMColor.fgPrimary : MMColor.fgSubtle)
            .frame(width: size, height: size)
            .background(kind == .patient ? MMColor.bgPrimarySubtle : MMColor.bgSubtle)
            .clipShape(Circle())
    }
}

private enum AvatarMetrics {
    static let size: CGFloat = 44
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        MMKVRow(key: "부위", value: "복부 (하복부 중앙)")
        MMKVRow(key: "강도", value: "많이 아파요", kind: .emphasis)
        MMKVRow(key: "복용약", value: "이부프로펜(증상 시)", kind: .link, action: {})
        HStack(spacing: MMSpace.s12) {
            MMAvatar(initial: "나", kind: .patient)
            MMAvatar(initial: "김", kind: .doctor)
        }
    }
    .padding(.horizontal, MMSize.gutter)
    .background(MMColor.bgCanvas)
}

/// `KV Row / Editing` (Figma `597:4801`) — 브리핑 카드 편집의 항목 줄(1e-1-E).
///
/// 읽는 줄과 다른 컴포넌트다. 키 폭이 60이 아니라 **52**이고, 값이 `border/strong`
/// 밑줄 위에 서며, 오른쪽 끝에 지우기가 붙는다. 줄 전체 오른쪽에 30을 비워 지우기 자리를
/// 만든다 — 값이 길어도 ✕ 아래로 들어가지 않게.
///
/// **축에서 오지 않은 줄(복용약 · 기저질환)은 고쳐도 보낼 곳이 없다.** 그 줄은 값을
/// 잠그고 지우기만 남긴다.
struct MMKVEditRow: View {
    let key: String
    @Binding var value: String
    /// 고칠 수 있는 줄인지. 축이 없는 줄은 `false`다.
    var isEditable: Bool = true
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(alignment: .top, spacing: MMSpace.s10) {
                Text(key)
                    .mmTextStyle(MMFont.bodyM)
                    .foregroundStyle(MMColor.fgSubtle)
                    .frame(width: KVEditMetrics.key, alignment: .leading)

                field
            }
            .padding(.trailing, KVEditMetrics.deleteGutter)
            .padding(.vertical, MMSpace.s14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(alignment: .trailing) {
            Button(action: onDelete) {
                MMIcon.close.view(size: MMSize.iconSm)
                    .foregroundStyle(MMColor.fgDefault)
                    .frame(width: MMSize.iconLg, height: MMSize.iconLg)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("\(key) 지우기")
        }
    }

    private var field: some View {
        VStack(spacing: 0) {
            Group {
                if isEditable {
                    TextField("", text: $value, axis: .vertical)
                        .mmTextStyle(MMFont.bodyL)
                        .foregroundStyle(MMColor.fgDefault)
                        .textFieldStyle(.plain)
                } else {
                    Text(value)
                        .mmTextStyle(MMFont.bodyL)
                        .foregroundStyle(MMColor.fgDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Rectangle()
                .fill(MMColor.borderStrong)
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

enum KVEditMetrics {
    /// 편집 줄의 키 폭. 읽는 줄(60)보다 좁다.
    static let key: CGFloat = 52
    /// 지우기 자리.
    static let deleteGutter: CGFloat = 30
}
