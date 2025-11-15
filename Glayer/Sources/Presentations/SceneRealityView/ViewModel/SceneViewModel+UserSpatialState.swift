import Foundation
import RealityKit

// MARK: - User Spatial State Management

extension SceneViewModel {

    /// 조이스틱 값으로 속도 업데이트 (rootEntity 위치 제어용)
    /// - Parameters:
    ///   - x: X축 값 (-1.0 ~ 1.0)
    ///   - z: Z축 값 (-1.0 ~ 1.0)
    func updateUserPositionFromJoystick(x: Double, z: Double) {
        // 조이스틱 값을 속도로 변환 (1.0 = 최대 속도, 필요에 따라 조정)
        let maxSpeed: Float = 0.05 // 초당 0.05미터
        let velocity = SIMD3<Float>(
            -Float(x) * maxSpeed,
            0, // Y축은 변경하지 않음
            Float(z) * maxSpeed
        )
        
        // 속도 업데이트
        joystickVelocity = velocity
    }
    
    /// 조이스틱 속도에 따라 userPosition 업데이트 (매 프레임 호출)
    /// - Parameter deltaTime: 이전 프레임부터 경과한 시간 (초)
    func updatePositionFromJoystickVelocity(deltaTime: Float) {
        // 속도가 0이면 업데이트하지 않음
        guard simd_length(joystickVelocity) > 0.001 else { return }
        
        // 속도 × 시간 = 이동 거리
        let movement = joystickVelocity * deltaTime
        
        // 현재 위치에 이동 거리 추가
        var state = userSpatialState
        state.userPosition = state.userPosition + movement
        userSpatialState = state
    }
    
    /// Head Anchor의 위치를 UserSpatialState에 동기화
    /// - Parameter position: Head Anchor의 월드 좌표계 위치
    func updateUserPosition(_ position: SIMD3<Float>) {
        // 현재 userPosition과 비교해서 변경이 있을 때만 업데이트 (성능 최적화)
        let currentPosition = userSpatialState.userPosition
        let threshold: Float = 0.01  // 1cm 이하 변화는 무시
        
        let distance = simd_distance(position, currentPosition)
        guard distance > threshold else { return }
        
        // UserSpatialState 업데이트
        var state = userSpatialState
        state.userPosition = position
        userSpatialState = state
    }

    /// View Mode 토글
    func toggleViewMode() {
        // userSpatialState의 viewMode 토글
        var state = userSpatialState
        state.viewMode.toggle()
        userSpatialState = state
        selectedEntity = nil
        
        // ViewModeUseCase 실행
        let viewModeUseCase = ViewModeUseCase(
            entityRepository: entityRepository,
            viewMode: state.viewMode
        )
        viewModeUseCase.execute()
        
        // 상태관리
        appStateManager.toggleLibraryVisibility()
    }
    
    /// Paused 상태 토글
    func togglePause() {
        // userSpatialState의 paused 토글
        var state = userSpatialState
        state.paused.toggle()
        userSpatialState = state
        
        // SceneAudioCoordinator에 전역 음소거 설정
        SceneAudioCoordinator.shared.setGlobalMute(state.paused)
    }
    
    /// Paused 상태 업데이트 (직접 값 설정)
    func updatePausedState(_ paused: Bool) {
        var state = userSpatialState
        state.paused = paused
        userSpatialState = state
        
        // SceneAudioCoordinator에 전역 음소거 설정
        SceneAudioCoordinator.shared.setGlobalMute(paused)
    }
}
