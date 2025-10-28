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
    @ObservedObject private var player = LibrarySoundPlayer.shared
    @State private var localProgress: Double = 0
    @State private var showRename = false
    @State private var draftTitle: String
    @State private var isFlashing = false
    @FocusState private var renameFocused: Bool
    
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
                
                if showRename {
                    TextField("이름", text: $draftTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .focused($renameFocused)
                        .submitLabel(.done)
                        .onAppear { renameFocused = true }
                        .frame(maxWidth: .infinity)
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
        .onTapGesture {
            guard !showRename else { return }
            withAnimation(.easeInOut(duration: 0.12)) { isFlashing = true }
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.20)) { isFlashing = false }
            }
        }
        .onLongPressGesture(
            minimumDuration: 0.35,
            maximumDistance: 22,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isFlashing = pressing
                }
            },
            perform: {
                showRename = true
            }
        )
        .popover(isPresented: $showRename, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            RenamePopover(
                id: asset.id,
                title: $draftTitle,
                onRename: { id, newTitle in viewModel.renameAsset(id: id, to: newTitle) },
                onDelete: { id in
                    if player.currentURL == asset.url { player.stop() }
                    viewModel.deleteAsset(id: id)
                },
                onCancel: { showRename = false }
            )
        }
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
