//
//  DebugBorder.swift
//  Glayer
//
//  Created by PenguinLand on 10/29/25.
//
import SwiftUI

extension View {
    /// visionOS의 Volume 또는 3D 뷰에 디버깅용 3D 테두리를 추가합니다.
    ///
    /// 이 메서드는 개발 중에 3D 공간의 경계를 시각적으로 확인하기 위해 사용됩니다.
    /// spatialOverlay를 사용하여 뷰의 앞면과 측면에 컬러 테두리를 렌더링합니다.
    ///
    /// - Parameter color: 테두리에 사용할 색상
    ///
    /// - Returns: 3D 테두리가 오버레이된 뷰
    ///
    /// ## 동작 방식
    /// - 앞면과 뒷면에 테두리 렌더링
    /// - Y축을 기준으로 90도 회전하여 좌우 측면에도 테두리 렌더링
    /// - 총 4개의 경계면(앞, 뒤, 좌, 우)이 표시됩니다
    ///
    /// ## 사용 예시
    /// ```swift
    /// // Volume 윈도우에서 디버그 테두리 표시
    /// WindowGroup(id: "VolumeWindow") {
    ///     VolumeContentView()
    ///         .debugBorder3D(.red)
    /// }
    /// .windowStyle(.volumetric)
    ///
    /// // 개발 모드에서만 조건부로 표시
    /// someView
    ///     #if DEBUG
    ///     .debugBorder3D(.green)
    ///     #endif
    /// ```
    ///
    /// - Note: 이 메서드는 디버깅 목적으로만 사용하며, 프로덕션 빌드에서는 제거하는 것이 좋습니다.
    func debugBorder3D(_ color: Color) -> some View {
        spatialOverlay {
            ZStack {
                // 앞면 테두리
                Color.clear.border(color, width: 4)

                // Y축 기준 90도 회전된 측면 테두리 (좌우)
                ZStack {
                    Color.clear.border(color, width: 4)
                    Spacer()
                    Color.clear.border(color, width: 4)
                }
                .rotation3DLayout(.degrees(90), axis: .y)

                // 뒷면 테두리
                Color.clear.border(color, width: 4)
            }
        }
    }
}
