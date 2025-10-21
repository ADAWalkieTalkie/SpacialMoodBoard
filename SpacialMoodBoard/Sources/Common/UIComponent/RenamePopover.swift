//
//  RenamePopover.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/13/25.
//

import SwiftUI

/// 이름 변경/복제/삭제 팝오버 (모든 액션이 옵셔널)
struct RenamePopover: View {
    
    // MARK: - Properties
    
    private let id: UUID
    private let onRename: ((_ id: UUID, _ newTitle: String) -> Void)?
    private let onDelete: ((_ id: UUID) -> Void)?
    private let onDuplicate: ((_ id: UUID, _ newTitle: String) -> Void)?
    private let onCancel: () -> Void
    
    @Binding private var title: String
    @FocusState private var isFocused: Bool
    
    // MARK: - Init
    
    /// Init
    /// - Parameters:
    ///   - id: 대상 에셋(또는 프로젝트)의 고유 식별자
    ///   - initialTitle: 텍스트필드에 표시할 초기 제목
    ///   - onRename: 이름 변경 콜백. 전달되지 않으면 해당 메뉴를 숨김
    ///   - onDelete: 삭제 콜백. 전달되지 않으면 해당 메뉴를 숨김
    ///   - onDuplicate: 복제 콜백. 전달되지 않으면 해당 메뉴를 숨김
    ///   - onCancel: 팝오버를 닫을 때 호출되는 콜백
    init(
        id: UUID,
        title: Binding<String>,
        onRename: ((_ id: UUID, _ newTitle: String) -> Void)? = nil,
        onDelete: ((_ id: UUID) -> Void)? = nil,
        onDuplicate: ((_ id: UUID, _ newTitle: String) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.id = id
        self._title = title
        self.onRename = onRename
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
        self.onCancel = onCancel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let onRename {
                Button{
                    onRename(id, title)
                    onCancel()
                } label: {
                    rowLabel("이름 변경", system: "pencil")
                }
                .buttonStyle(.plain)
            }
            
            if let onDuplicate {
                Button {
                    onDuplicate(id, title)
                    onCancel()
                } label: {
                    rowLabel("복제 하기", system: "plus.square.on.square")
                }
                .buttonStyle(.plain)
            }
            
            if let onDelete {
                Button(role: .destructive) {
                    onDelete(id)
                    onCancel()
                } label: {
                    rowLabel("삭제하기", system: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 280)
        .glassBackgroundEffect()
    }
    
    // MARK: - Methods
    
    /// 액션 행 공통 레이아웃 뷰를 생성
    /// - Parameters:
    ///   - text: 행에 표시할 레이블 텍스트
    ///   - system: SF Symbols 시스템 이미지 이름
    /// - Returns: 아이콘과 텍스트가 포함된 한 줄짜리 행 뷰
    @ViewBuilder
    private func rowLabel(_ text: String, system: String) -> some View {
        HStack {
            Text(text)
            Spacer()
            Image(systemName: system)
                .frame(height: 22)
        }
        .font(.system(size: 17, weight: .regular))
        .padding(.vertical, 16)
        .padding(.leading, 20)
        .padding(.trailing, 19)
    }
}
