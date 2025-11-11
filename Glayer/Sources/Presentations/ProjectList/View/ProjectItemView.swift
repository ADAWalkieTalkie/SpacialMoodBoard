//
//  ProjectItemView.swift
//  Glayer
//
//  Created by PenguinLand on 10/12/25.
//

import SwiftUI

struct ProjectItemView: View {

    // MARK: - Properties

    private let project: Project

    @Environment(ProjectListViewModel.self) private var viewModel
    @State private var showRenamePopover = false
    @State private var isRenaming = false
    @State private var isTextFieldFocused = false
    @State private var draftTitle: String
    @State private var isFlashing = false
    @State private var showDeleteAlert = false

    // MARK: - Init

    /// Init
    ///  - Parameter project: 선택한 project
    init(project: Project) {
        self.project = project
        self._draftTitle = State(
            initialValue: project.title.deletingPathExtension
        )
    }

    // MARK: - Body

    var body: some View {
        VStack {
            ZStack {
                Color.clear
                    .background(
                        Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.2)
                    )
                    .aspectRatio(320 / 250, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 30))

                // 썸네일 영역
                // 사다리꼴 모양 (채우기)
                TrapezoidShape()
                    .fill(Color.white.opacity(0.3))

                // 사다리꼴 테두리
                TrapezoidShape()
                    .stroke(Color.white, lineWidth: 4)
            }

            if isRenaming {
                SelectAllTextField(
                    text: $draftTitle,
                    isFirstResponder: $isTextFieldFocused,
                    onSubmit: { commitRenameIfNeeded() },
                    alignment: .center,
                    usesIntrinsicWidth: true,
                    minWidth: 40,
                    horizontalPadding: 8
                )
                .frame(height: 26)
            } else {
                Text(project.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(height: 26)
            }
        }
        .padding(20)
        .contentShape(.hoverEffect, .rect(cornerRadius: 30))
        .hoverEffect()
        .buttonStyle(.plain)
        .background(isFlashing ? .white.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .onTapGesture(perform: tapFlash)
        .onLongPressGesture(
            minimumDuration: 0.35,
            maximumDistance: 22,
            pressing: { p in
                withAnimation(.easeInOut(duration: 0.12)) { isFlashing = p }
            },
            perform: { showRenamePopover = true }
        )
        .popover(
            isPresented: $showRenamePopover,
            attachmentAnchor: .point(.bottom),
            arrowEdge: .top
        ) {
            RenamePopover(
                id: project.id.uuidString,
                title: $draftTitle,
                onRename: { startInlineRename() },
                onDelete: { id in showDeleteAlert = true },
                onDuplicate: { id, newTitle in },  // TODO: - 프로젝트 복사 필요
                onCancel: { showRenamePopover = false }
            )
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if !focused { commitRenameIfNeeded() }
        }
        .alert(
            String(
                localized: "해당 프로젝트를 삭제하시겠습니까?",
                comment: "Delete project confirmation"
            ),
            isPresented: $showDeleteAlert
        ) {
            Button(
                String(localized: "아니오", comment: "Cancel button"),
                role: .cancel
            ) {}
            Button(
                String(localized: "예", comment: "Confirm button"),
                role: .destructive
            ) {
                viewModel.deleteProject(project: project)
            }
        }
    }

    // MARK: - Methods

    /// 짧게 깜박이는 애니메이션 효과를 주어 사용자 상호작용(탭)을 피드백
    /// - 팝오버가 열려 있을 땐 실행되지 않음
    private func tapFlash() {
        guard !showRenamePopover else { return }
        withAnimation(.easeInOut(duration: 0.12)) { isFlashing = true }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.20)) { isFlashing = false }
        }
    }

    /// 팝오버를 닫고 인라인 이름 수정 모드로 전환
    /// - 한 프레임 뒤에 포커스를 활성화하여 키보드가 즉시 올라오도록 함
    private func startInlineRename() {
        showRenamePopover = false
        isRenaming = true
        DispatchQueue.main.async {
            isTextFieldFocused = true
        }
    }

    /// 이름 변경이 필요한 경우에만 변경 사항을 커밋(저장)
    /// - 공백이거나 기존 이름과 동일하면 무시
    /// - 커밋 후 편집 및 포커스 상태를 종료
    private func commitRenameIfNeeded() {
        guard isRenaming else { return }
        defer {
            isRenaming = false
            isTextFieldFocused = false
        }
        let original = project.title.deletingPathExtension

        guard !draftTitle.isEmpty, draftTitle != original else { return }
        viewModel.updateProjectTitle(project: project, newTitle: draftTitle)
    }
}

// MARK: - TrapezoidShape

/// 썸네일 이미지
struct TrapezoidShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // 사다리꼴 좌표 (정규화된 값)
        let bottomLeft = CGPoint(x: width * 0.25, y: height * 0.39)
        let bottomRight = CGPoint(x: width * 0.75, y: height * 0.39)
        let topRight = CGPoint(x: width * 0.90, y: height * 0.62)
        let topLeft = CGPoint(x: width * 0.10, y: height * 0.62)

        // 사다리꼴 그리기
        path.move(to: bottomLeft)
        path.addLine(to: bottomRight)
        path.addLine(to: topRight)
        path.addLine(to: topLeft)
        path.closeSubpath()

        return path
    }
}
