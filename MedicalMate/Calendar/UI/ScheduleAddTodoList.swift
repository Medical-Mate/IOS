import SwiftUI

/// `1r-4-C` 진료 전 할 일(`3663:15108` · `15151` · `15201` · `15250`).
///
/// 네 장이 한 자리의 네 단계다 — 목록 · 빈 칸이 선 뒤 · 적는 중 · 다 적은 뒤.
extension ScheduleAddView {
    func todoList(_ model: ScheduleAddModel, focus: FocusState<UUID?>.Binding) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(model.todos.enumerated()), id: \.element.id) { index, todo in
                HStack(spacing: MMSpace.s10) {
                    MMSelectBox(isOn: .constant(todo.isDone))
                        .allowsHitTesting(false)
                        .onTapGesture { model.toggleTodo(todo) }

                    // **빈 칸에는 안내 글을 넣지 않는다.** 시안(`3663:15151`)이 밑줄 친
                    // 빈 자리를 그려 두었고, 적기 시작하면 밑줄이 사라진다
                    // (`3663:15250`). 질문 빈 칸(`MMCallout`)과 같은 모양이다.
                    VStack(spacing: ScheduleMetrics.todoFieldGap) {
                        TextField("", text: model.todo(at: index))
                            .mmTextStyle(MMFont.bodyM)
                            .foregroundStyle(MMColor.fgDefault)
                            .textFieldStyle(.plain)
                            .focused(focus, equals: todo.id)
                        if todo.text.isEmpty {
                            Rectangle()
                                .fill(MMColor.borderSubtle)
                                .frame(height: 1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Button { model.deleteTodo(todo) } label: {
                        MMIcon.close.view(size: MMSize.iconMd)
                            .foregroundStyle(MMColor.fgSubtle)
                            .frame(width: MMSize.touchMin, height: MMSize.touchMin)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(CalendarDayView.todoDeleteLabel(todo.text))
                }
                .frame(height: ScheduleMetrics.rowHeight)
            }
        }
    }
}
