import Foundation
import RealityKit

// MARK: - User Spatial State Management

extension SceneViewModel {
    
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
}