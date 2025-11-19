import Foundation

/// 3D Scene의 중앙 집중식 상수 관리
///
/// Floor 사이즈와 관련된 모든 값을 한 곳에서 관리하여,
/// 크기 변경 시 여러 파일을 수정하지 않아도 되도록 합니다.
///
/// ## 사용법
/// Floor 크기를 변경하려면 `floorSize`만 수정하면 됩니다.
/// 관련된 모든 값(이동 범위, Volume 스케일, Immersive 위치 등)이 자동으로 계산됩니다.
struct SceneConstants {
    // MARK: - 기준 값

    /// 바닥의 기본 크기 (미터 단위)
    /// 이 값을 변경하면 모든 관련 값이 자동으로 계산됩니다.
    static let floorSize: Float = 2.0

    // MARK: - 계산된 값들 (자동으로 동기화)

    /// 바닥 크기의 절반
    static var floorHalfSize: Float {
        floorSize / 2.0
    }

    /// 바닥을 하단에 정렬하기 위한 Y축 오프셋
    /// (바닥 중심을 기준으로 절반만큼 아래로 이동)
    static var floorYOffset: Float {
        -floorHalfSize
    }

    /// 오브젝트 이동 범위의 기본값
    /// 바닥 크기를 기준으로 자동 계산
    static var defaultMovementBounds: MovementBounds {
        let half = floorHalfSize
        return MovementBounds(
            minX: -half, maxX: half,
            minY: -half, maxY: half,
            minZ: -half, maxZ: half
        )
    }
    
    static var floorOutlineOffset: Float {
        floorSize / 10.0
    }

    // MARK: - Volume 모드 설정

    struct VolumeMode {
        /// Volume 윈도우에서 표시할 때의 기본 스케일
        /// (floorSize가 2.0일 때 0.5 = 1.0이 되도록 조정)
        static var baseScale: Float {
            1.0 / SceneConstants.floorSize
        }
    }

    // MARK: - Immersive 모드 설정

    struct ImmersiveMode {
        /// Immersive 모드에서 전체 씬의 확대 배율
        static let scale: Float = 8.0

        /// Immersive 모드에서 rootEntity의 Y축 위치
        /// (바닥이 실제 바닥 높이에 오도록 조정)
        static var yPosition: Float {
            scale
        }
    }
}
