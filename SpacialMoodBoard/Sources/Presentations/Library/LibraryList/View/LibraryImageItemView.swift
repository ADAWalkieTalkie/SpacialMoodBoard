//
//  LibraryImageItemView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/9/25.
//

import SwiftUI

struct LibraryImageItemView: View {
    
    // MARK: - Properties

    private let asset: Asset

    @Environment(LibraryViewModel.self) private var viewModel
    @Environment(SceneViewModel.self) private var sceneViewModel
    @State private var showRenamePopover = false
    @State private var isRenaming = false
    @State private var isTextFieldFocused = false
    @State private var draftTitle: String
    @State private var isFlashing = false
    
    // MARK: - Init
    
    /// Init
    ///  - Parameter asset: 표시할 사운드 에셋(타입은 `.image` 여야 함)
    init(asset: Asset) {
        precondition(asset.type == .image, "LibraryImageItemView는 .image 에셋만 지원합니다.")
        self.asset = asset
        self._draftTitle = State(initialValue: asset.filename.deletingPathExtension)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if isFlashing {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .glassBackgroundEffect(
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .transition(.opacity)
                    .zIndex(-1)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                URLImageView(url: asset.url)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    if isRenaming {
                        SelectAllTextField(
                            text: $draftTitle,
                            isFirstResponder: $isTextFieldFocused,
                            onSubmit: { commitRenameIfNeeded() }
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                    } else {
                        Text(asset.filename.deletingPathExtension)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    
                    Text(Self.formatDate(asset.createdAt))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture(perform: tapFlash)
        .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 22,
                            pressing: { p in withAnimation(.easeInOut(duration: 0.12)) { isFlashing = p } },
                            perform: { showRenamePopover = true }
        )
        .popover(isPresented: $showRenamePopover, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            RenamePopover(
                id: asset.id,
                title: $draftTitle,
                onRename: {
                    startInlineRename()
                },
                onDelete: { id in viewModel.deleteAsset(id: id) },
                onAddToFloor: { _ in
                    if sceneViewModel.spacialEnvironment.floorAssetId == asset.id {
                        sceneViewModel.removeFloorImage()
                    } else {
                        sceneViewModel.applyFloorImage(from: asset)
                    }
                },
                isCurrentFloorImage: sceneViewModel.spacialEnvironment.floorAssetId == asset.id,
                onCancel: { showRenamePopover = false }
            )
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if !focused { commitRenameIfNeeded() }
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
        let original = asset.filename.deletingPathExtension
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != original else { return }
        viewModel.renameAsset(id: asset.id, to: trimmed)
    }
    
    /// Date -> "yyyy.M.d a h:mm" 포맷
    /// - Parameter date: Date
    /// - Returns: "yyyy.M.d a h:mm" 포맷
    private static func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = .autoupdatingCurrent
        df.amSymbol = "AM"; df.pmSymbol = "PM"
        df.dateFormat = "yyyy.M.d a h:mm"
        return df.string(from: date)
    }
}

// MARK: - Previews

#Preview {
    LibraryImageItemView(
        asset: Asset(
            id: UUID().uuidString,
            type: .image,
            filename: "Astronaut",
            url: URL(string: "https://i.ibb.co/0yhHJbfK/image-23.png")!,
            createdAt: Date()
        )
    )
    .frame(width: 220, height: 272)
}
