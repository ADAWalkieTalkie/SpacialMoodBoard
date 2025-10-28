//
//  LibrarySoundItemView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI

struct LibrarySoundItemView: View {
    
    // MARK: - Properties
    
    private let asset: Asset

    @Environment(LibraryViewModel.self) private var viewModel
    @ObservedObject private var player = SoundPlayer.shared
    @State private var localProgress: Double = 0
    @State private var showRenamePopover = false
    @State private var isRenaming = false
    @State private var isTextFieldFocused = false
    @State private var draftTitle: String
    @State private var isFlashing = false
    
    // MARK: - Init
    
    /// Init
    ///  - Parameter asset: 표시할 사운드 에셋(타입은 `.sound` 여야 함)
    init(asset: Asset) {
        precondition(asset.type == .sound, "LibrarySoundItemView는 .sound 에셋만 지원합니다.")
        self.asset = asset
        self._draftTitle = State(initialValue: asset.filename.deletingPathExtension)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if isFlashing {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.clear)
                    .glassBackgroundEffect(
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .transition(.opacity)
                    .zIndex(-1)
            }
            
            HStack(alignment: .center) {
                Button {
                    guard asset.type == .sound else { return }
                    if player.currentURL == asset.url {
                        player.isPlaying ? player.pause() : player.resume()
                    } else {
                        player.play(url: asset.url, from: 0)
                    }
                } label: {
                    Image(systemName: (player.currentURL == asset.url && player.isPlaying) ? "pause.circle" : "play.circle")
                        .font(.system(size: 40, weight: .medium))
                }
                .frame(width: 52, height: 48)
                
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
                
                Spacer()
                
                WaveformScrubberView(
                    samples: asset.sound?.waveform ?? [],
                    progress: Binding(
                        get: { player.currentURL == asset.url ? player.progress : localProgress },
                        set: { newVal in
                            if player.currentURL == asset.url {
                                player.seek(to: newVal)
                            } else {
                                localProgress = newVal
                            }
                        }
                    ),
                    onScrubStart: {
                        if player.currentURL == asset.url, player.isPlaying { player.pause() }
                    },
                    onScrubEnd: { f in
                        player.play(url: asset.url, from: f)
                    }
                )
                .frame(width: 382, height: 30)
                
                Text(Self.formatDuration(asset.sound?.duration ?? 0))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
        }
        .onChange(of: player.currentURL) { _, _ in
            if player.currentURL != asset.url { localProgress = 0 }
        }
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
                onCancel: { showRenamePopover = false }
            )
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if !focused { commitRenameIfNeeded() }
        }
    }
    
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
    
    // MARK: - Methods
    
    /// 초 → "MM:SS" 포맷
    /// - Parameter seconds: TimeInterval
    /// - Returns: "MM:SS" 포맷
    private static func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds > 0 else { return "00:00" }
        let s = Int(round(seconds))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}
