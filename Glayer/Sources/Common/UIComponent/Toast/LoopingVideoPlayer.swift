//
//  LoopingVideoPlayer.swift
//  Glayer
//
//  Created by jeongminji on 11/19/25.
//

import SwiftUI
import AVKit
import AVFoundation

struct LoopingVideoView: View {
    
    // MARK: - Properties
    
    private let videoName: String
    private let fileExtension: String
    private let folderName: String
    
    @State private var player: AVPlayer?
    @State private var aspectRatio: CGFloat?
    
    // MARK: - Init
    
    /// 무한 루프 재생용 비디오 뷰 초기화
    /// - Parameters:
    ///   - videoName: 번들에 포함된 비디오 리소스 이름 (확장자 제외)
    ///   - fileExtension: 비디오 파일 확장자 (기본값: `"mp4"`)
    init(videoName: String, fileExtension: String = "mp4", folderName: String) {
        self.videoName = videoName
        self.fileExtension = fileExtension
        self.folderName = folderName
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let player {
                PlayerLayerView(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                    .allowsHitTesting(false) 
            } else {
                ZStack {
                    Color.gray.opacity(0.08)
                    Image(systemName: "play.slash.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aspectRatio(aspectRatio ?? (1.0/1.0), contentMode: .fit)
        .frame(maxWidth: .infinity)
        .task {
            await setupPlayerIfNeeded()
        }
    }
    
    // MARK: - Methods
    
    /// 아직 플레이어가 없다면, 번들에서 비디오를 로드해 `AVPlayer`를 만들고
    /// 끝까지 재생되면 다시 처음부터 재생하도록 무한 루프 설정
    private func setupPlayerIfNeeded() async {
        guard player == nil,
              let url = Bundle.main.url(
                forResource: videoName,
                withExtension: fileExtension,
                subdirectory: folderName
              )
        else { return }
        
        let asset = AVURLAsset(url: url)
        
        do {
            let tracks = try await asset.load(.tracks)
            
            if let videoTrack = tracks.first {
                let naturalSize: CGSize = try await videoTrack.load(.naturalSize)
                let transform: CGAffineTransform = try await videoTrack.load(.preferredTransform)
                
                let transformed = naturalSize.applying(transform)
                let w = abs(transformed.width)
                let h = abs(transformed.height)
                
                if h > 0 {
                    await MainActor.run {
                        self.aspectRatio = w / h
                    }
                }
            }
        } catch { }
        
        let item   = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        await MainActor.run {
            self.player = player
        }
    }
}

// MARK: - SubView

fileprivate struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}
