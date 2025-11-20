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
        let maxSpeed: Float = 1 // 초당 1cm
        let velocity = SIMD3<Float>(
            -Float(x) * maxSpeed,
            0, // Y축은 변경하지 않음
            Float(z) * maxSpeed
        )
        
        // 속도 업데이트
        joystickVelocity = velocity
    }
    
    /// 조이스틱 속도에 따라 userScenePosition 업데이트 (매 프레임 호출)
    /// - Parameter deltaTime: 이전 프레임부터 경과한 시간 (초)
    func updatePositionFromJoystickVelocity(deltaTime: Float) {
        let maxDistance: Float = SceneConstants.floorHalfSize * 8
        let minDistance: Float = -SceneConstants.floorHalfSize * 8
        // 속도가 0이면 업데이트하지 않음
        guard simd_length(joystickVelocity) > 0.001 else { return }
        
        // 속도 × 시간 = 이동 거리
        let movement = joystickVelocity * deltaTime

        // 현재 위치에 이동 거리 추가
        var state = userSpatialState
        var newPosition = state.userScenePosition + movement
        
        // x, z 값을 -1 ~ +1 범위로 제한
        newPosition.x = max(minDistance, min(maxDistance, newPosition.x))
        newPosition.z = max(minDistance, min(maxDistance, newPosition.z))
        
        state.userScenePosition = newPosition
        userSpatialState = state
    }

    /// Head Anchor의 위치와 회전을 UserSpatialState에 동기화
    /// - Parameters:
    ///   - position: Head Anchor의 위치 (Volume: rootEntity 기준, Immersive: 월드 좌표계)
    ///   - rotation: Head Anchor의 회전 (quaternion as SIMD4)
    func updateHeadAnchorState(position: SIMD3<Float>, rotation: SIMD4<Float>) {
        var state = userSpatialState
        let threshold: Float = 0.01
        
        // 위치 업데이트 (threshold 체크)
        let positionDistance = simd_distance(position, state.headAnchorState.position)
        if positionDistance > threshold {
            state.headAnchorState.position = position
        }
        
        // 회전 업데이트 (threshold 체크)
        let rotationDistance = simd_distance(rotation, state.headAnchorState.rotation)
        if rotationDistance > threshold {
            state.headAnchorState.rotation = rotation
        }
        
        userSpatialState = state
    }

    func resetRootEntityPosition() {
        var state = userSpatialState
        state.userScenePosition = [0, 0, 0]
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
