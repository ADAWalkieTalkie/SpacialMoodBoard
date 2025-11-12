//
//  SceneAudioCoordinator.swift
//  Glayer
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
    private var isGlobalMute = false
    
    /// 현재 “재생 중”으로 추적되는 ID 집합
    private var playing: Set<UUID> = []
    
    private enum PauseScope {
        case external    // 라이브러리(외부) 인터럽션
        case globalMute  // 툴바 글로벌 음소거
    }
    
    /// 정지 사유, “인터럽션 시작 시점에 재생 중이던 ID 집합”을 스택에 보관
    private var pauseStack: [(scope: PauseScope, snapshot: Set<UUID>)] = []
    
    // MARK: - Methods
    
    /// 새로운 SoundEntity를 등록하여 컨트롤러를 추적
    /// - Parameters:
    ///   - entityId: 엔티티의 고유 식별자(UUID)
    ///   - controller: 등록할 `AudioPlaybackController`
    ///   - shouldStartPlaying: 기본 재생 의도 (초기 볼륨 > 0 등)
    func register(entityId: UUID, controller: AudioPlaybackController, shouldStartPlaying: Bool) {
        controllers[entityId] = WeakController(controller: controller)
        
        if isGlobalMute {
            controller.pause()
            if shouldStartPlaying { appendToGlobalMuteSnapshot(entityId) }
        } else {
            if shouldStartPlaying {
                controller.play()
                playing.insert(entityId)
            }
        }
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
    
    /// 특정 엔티티 재생 시작(또는 재개)
    /// - Parameter id: 엔티티 UUID
    func play(_ id: UUID) {
        guard let c = controller(for: id) else { return }
        guard !isGlobalMute else {
            playing.remove(id)
            return
        }
        c.play()
        playing.insert(id)
    }
    
    /// 특정 엔티티 일시정지
    /// - Parameter id: 엔티티 UUID
    func pause(_ id: UUID) {
        guard let c = controller(for: id) else { return }
        c.pause()
        playing.remove(id)
        
        if isGlobalMute, var top = pauseStack.last, top.scope == .globalMute {
            top.snapshot.remove(id)
            pauseStack[pauseStack.count - 1] = top
        }
    }
    
    /// 특정 엔티티 정지(재생 위치 초기화 포함)
    /// - Parameter id: 엔티티 UUID
    func stop(_ id: UUID) {
        guard let c = controller(for: id) else { return }
        c.stop()
        playing.remove(id)
        
        if isGlobalMute, var top = pauseStack.last, top.scope == .globalMute {
            top.snapshot.remove(id)
            pauseStack[pauseStack.count - 1] = top
        }
    }
    
    /// 특정 엔티티 볼륨(gain, dB)을 설정
    /// - Parameters:
    ///   - db: dB 단위(예: 0 = 원음, 음수는 감쇠)
    ///   - id: 엔티티 UUID
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
    /// 공통: 현재 재생 중 스냅샷을 스택에 push하고 모두 pause
    /// - Parameter scope: 정지 사유(외부 인터럽션/글로벌 음소거)
    private func pushPause(_ scope: PauseScope) {
        cleanup()

        if pauseStack.last?.scope == scope { return }
        
        let snapshot: Set<UUID> = (!playing.isEmpty) ? playing : (pauseStack.last?.snapshot ?? [])

        pauseStack.append((scope: scope, snapshot: snapshot))

        controllers.values.forEach { $0.controller?.pause() }
        playing.removeAll()
    }
    
    /// 공통: 스택의 top이 `scope`일 때만 pop & 복원
    /// - Parameter scope: 해제할 정지 사유
    private func popPause(_ scope: PauseScope) {
        cleanup()
        
        guard let top = pauseStack.last else { return }
        if top.scope != scope {
            if let idx = pauseStack.lastIndex(where: { $0.scope == scope }) {
                pauseStack.remove(at: idx)
            }
            return
        }
        _ = pauseStack.popLast()

        guard pauseStack.isEmpty else { return }

        try? AVAudioSession.sharedInstance().setActive(true)
        for id in top.snapshot {
            if let c = controllers[id]?.controller {
                c.play()
                playing.insert(id)
            }
        }
    }
    
    // MARK: - 외부(라이브러리) 인터럽션 API
    
    /// 라이브러리 재생 시작 등 외부 인터럽션 시작: 전부 pause + 스냅샷 푸시
    func beginExternalInterruption() {
        pushPause(.external)
    }
    
    /// 외부 인터럽션 종료: 스택 top이 external이면 해당 스냅샷만 복원
    func endExternalInterruption() {
        popPause(.external)
    }
    
    // MARK: - 글로벌 음소거 API (툴바)
    
    func setGlobalMute(_ enabled: Bool) {
        if enabled {
            guard !isGlobalMute else { return }
            isGlobalMute = true
            pushPause(.globalMute)
        } else {
            guard isGlobalMute else { return }
            isGlobalMute = false
            popPause(.globalMute)
        }
    }
    
    /// 현재 글로벌 뮤트 스냅샷에 id를 추가 (뮤트 해제 시 자동 재생되도록)
    /// - Parameter id: 추가할 사운드 오브젝트의 id
    private func appendToGlobalMuteSnapshot(_ id: UUID) {
        guard var top = pauseStack.last, top.scope == .globalMute else { return }
        top.snapshot.insert(id)
        pauseStack[pauseStack.count - 1] = top
    }
    
    // MARK: - Housekeeping
    
    /// 컨트롤러 약참조 정리 + 존재하지 않는 ID를 `playing`에서 제거
    private func cleanup() {
        controllers = controllers.filter { $0.value.controller != nil }
        playing = playing.filter { controllers[$0]?.controller != nil }
    }
}
