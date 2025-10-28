//
//  LibrarySoundPlayer.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import Foundation
import AVFoundation
import Combine

/// 라이브러리(목록)에서 오디오를 재생하기 위한 싱글턴 플레이어
/// - 한 번에 **오직 하나의 파일**만 재생되도록 관리
/// - 동일 URL에 대해 `play(url:)`를 다시 호출하면 **토글(재생/일시정지)**
/// - `progress`는 0...1로 노멀라이즈된 재생 진행도
@MainActor
final class LibrarySoundPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    // MARK: - Properties
    
    static let shared = LibrarySoundPlayer()
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var progress: Double = 0
    
    private var player: AVAudioPlayer?
    private var tick: AnyCancellable?
    private(set) var currentURL: URL?
    
    /// 외부 인터럽션 활성화 상태(중복 begin/end 방지)
    private var isInterruptionActive = false
    private var wasPlayingBeforeInterruption = false
    
    // MARK: - Init
    
    override init() {
        super.init()
        configureAudioSession()
        observeAudioSessionNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods
    
    /// 오디오 재생, 동일 URL로 다시 호출 시 토글(재생/일시정지) 동작
    /// - Parameters:
    ///   - url: 재생할 오디오 파일의 URL
    ///   - fraction: 처음 재생 시작 지점(0...1). `nil`이면 현재 위치 또는 처음에서 시작
    func play(url: URL, from fraction: Double? = nil) {
        if let _ = player, currentURL == url {
            // 같은 트랙이면 토글
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }
        
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            player = p
            currentURL = url
            player?.prepareToPlay()
            if let f = fraction { seek(to: f) } else { progress = 0 }
            resume() // 실제 재생 시작은 resume()이 담당
        } catch {
            print("🔊 AVAudioPlayer error:", error)
        }
    }
    
    /// 일시정지 상태에서 재생 재개
    func resume() {
        guard let p = player else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        p.play()
        isPlaying = true
        startTick()

        SceneAudioCoordinator.shared.beginExternalInterruption()
    }
    
    /// 현재 재생 중인 트랙 일시정지
    func pause() {
        player?.pause()
        isPlaying = false
        stopTickIfNeeded()
        
        SceneAudioCoordinator.shared.endExternalInterruption()
    }
    
    /// 재생을 완전히 멈추고, 시간을 처음(0)으로 리셋
    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        progress = 0
        stopTickIfNeeded()
        
        SceneAudioCoordinator.shared.endExternalInterruption()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    /// 지정된 진행도로 이동(시크)
    /// - Parameter fraction: 0...1 범위의 진행도. 범위를 벗어나면 자동 클램프
    func seek(to fraction: Double) {
        guard let p = player, p.duration > 0 else { return }
        let clamped = max(0, min(1, fraction))
        p.currentTime = p.duration * clamped
        progress = clamped
    }
    
    /// 재생 진행도를 주기적으로 갱신하는 타이머 시작
    private func startTick() {
        stopTickIfNeeded()
        tick = Timer.publish(every: 1.0/30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let p = self.player, p.duration > 0 else { return }
                self.progress = p.currentTime / p.duration
                if !p.isPlaying { self.isPlaying = false; self.stopTickIfNeeded() }
            }
    }
    
    /// 진행도 타이머 중지
    private func stopTickIfNeeded() {
        tick?.cancel()
        tick = nil
    }
    
    // MARK: - Session
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        } catch {
            print("⚠️ configureAudioSession error:", error)
        }
    }
    
    @inline(__always)
    private func ensureSessionActive() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setActive(true)
    }
    private func observeAudioSessionNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption(_:)),
                       name: AVAudioSession.interruptionNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleRouteChange(_:)),
                       name: AVAudioSession.routeChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleMediaServicesReset),
                       name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }
    
    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying { pause() }
        case .ended:
            if wasPlayingBeforeInterruption {
                // 재생 의도가 있었으면 바로 복구
                resume()
            }
            // ❌ 여기서 setActive(false) 하지 마!
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ note: Notification) {
        guard let info = note.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        switch reason {
        case .oldDeviceUnavailable:
            if isPlaying { pause() }
        case .newDeviceAvailable:
            if wasPlayingBeforeInterruption { resume() }
        default:
            break
        }
    }
    
    @objc private func handleMediaServicesReset() {
        configureAudioSession()
        if let url = currentURL, isPlaying {
            play(url: url, from: progress)
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension LibrarySoundPlayer {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTickIfNeeded()
        SceneAudioCoordinator.shared.endExternalInterruption()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        stopTickIfNeeded()
        SceneAudioCoordinator.shared.endExternalInterruption()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
