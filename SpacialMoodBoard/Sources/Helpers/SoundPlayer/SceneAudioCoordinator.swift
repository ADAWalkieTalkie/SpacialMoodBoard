//
//  SceneAudioCoordinator.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import RealityKit
import Foundation
import AVFAudio

/// 씬 안의 모든 SoundEntity 컨트롤러를 관리하는 코디네이터
/// LibrarySoundPlayer에서 사운드 재생시, 씬 안의 모든 SoundEntity 사운드 일시 정지
@MainActor
final class SceneAudioCoordinator {
    
    // MARK: - Properties
    
    static let shared = SceneAudioCoordinator()
    
    private struct WeakController { weak var controller: AudioPlaybackController? }
    private var controllers: [UUID: WeakController] = [:]
    
    
    /// 현재 “재생 중”으로 추적되는 ID 집합
    private var playing: Set<UUID> = []
    
    /// 외부 인터럽션(라이브러리 재생 등) 동안
    /// “인터럽션 시작 시점에 재생 중이던 ID 집합”을 스택에 보관
    private var interruptionStack: [Set<UUID>] = []
    
    // MARK: - Methods
    
    /// 새로운 SoundEntity를 등록하여 컨트롤러를 추적
    /// - Parameters:
    ///   - entityId: 엔티티의 고유 식별자(UUID)
    ///   - controller: 등록할 `AudioPlaybackController` 인스턴스
    func register(entityId: UUID, controller: AudioPlaybackController) {
        controllers[entityId] = WeakController(controller: controller)
    }
    
    /// 삭제된 엔티티의 컨트롤러를 등록 목록에서 제거
    /// - Parameter entityId: 제거할 엔티티의 UUID
    func unregister(entityId: UUID) {
        controllers.removeValue(forKey: entityId)
    }
    
    // MARK: - 개별 오디오 관리
    
    /// 개별 조회
    /// - Parameter id: 조회할 UUID
    /// - Returns: 개별 `AudioPlaybackController` 인스턴스
    func controller(for id: UUID) -> AudioPlaybackController? {
        if controllers[id]?.controller == nil {
            controllers[id] = nil
            return nil
        }
        return controllers[id]?.controller
    }
    
    func play(_ id: UUID) {
        guard let c = controller(for: id) else { return }
        c.play()
        playing.insert(id)
    }
    
    func pause(_ id: UUID) {
        guard let c = controller(for: id) else { return }
        c.pause()
        playing.remove(id)
    }
    
    func stop(_ id: UUID) {
        guard let c = controller(for: id) else { return }
        c.stop()
        playing.remove(id)
    }
    
    func setGain(_ db: RealityKit.Audio.Decibel, for id: UUID) {
        controller(for: id)?.gain = db
    }
    
    // MARK: - 전체 오디오 관리
    
    /// 현재 등록된 모든 오디오 컨트롤러를 일시정지
    func pauseAll() {
        controllers = controllers.filter { $0.value.controller != nil }
        controllers.values.forEach { $0.controller?.pause() }
    }
    
    /// 현재 등록된 모든 오디오 컨트롤러를 재생(Resume)
    func resumeAll() {
        controllers = controllers.filter { $0.value.controller != nil }
        controllers.values.forEach { $0.controller?.play() }
    }
    
    /// 전체 볼륨(gain)을 일괄적으로 조정
    /// - Parameter gain: 설정할 볼륨 값 (디시벨 단위)
    func setGainAll(_ gain: Float) {
        controllers = controllers.filter { $0.value.controller != nil }
        controllers.values.forEach { $0.controller?.gain = RealityKit.Audio.Decibel(gain) }
    }
}

extension SceneAudioCoordinator {
    // MARK: - Interruption (LibrarySoundPlayer 연동)
    
    /// 외부 인터럽션 시작:
    /// 1) 현재 재생 중이던 ID 스냅샷 저장
    /// 2) 전부 일시정지
    func beginExternalInterruption() {
        cleanup()
        interruptionStack.append(playing)
        controllers.values.forEach { $0.controller?.pause() }
        playing.removeAll()
    }
    
    /// 외부 인터럽션 종료:
    /// 1) 마지막 스냅샷을 꺼내서
    /// 2) 그 집합만 재생 복원
    func endExternalInterruption() {
        cleanup()
        try? AVAudioSession.sharedInstance().setActive(true)
        
        guard let snapshot = interruptionStack.popLast() else { return }
        for id in snapshot {
            if let c = controllers[id]?.controller {
                c.play()
                playing.insert(id)
            }
        }
    }
    
    // MARK: - Housekeeping
    
    private func cleanup() {
        controllers = controllers.filter { $0.value.controller != nil }
        playing = playing.filter { controllers[$0]?.controller != nil }
    }
}
