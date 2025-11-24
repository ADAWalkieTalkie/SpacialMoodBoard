//
//  UVRect.swift
//  Glayer
//
//  Created by jeongminji on 11/13/25.
//

import Foundation
import RealityKit
import CoreGraphics

/// 0~1 UV 공간의 사각형. (x, y, width, height), y는 위→아래 증가 가정
/// RealityKit textureTransform 적용 시 y 보정을 내부에서 처리
struct UVRect: Codable, Hashable, Sendable {
    var x: Float
    var y: Float
    var width: Float
    var height: Float
    
    // MARK: - Init
    
    /// UV 좌표 공간에서 사각형을 초기화 / 기본값은 전체 텍스처 영역을 나타내는 `(x: 0, y: 0, width: 1, height: 1)`
    /// - Parameters:
    ///   - x: 사각형의 **왼쪽 상단 X 좌표** (0~1 사이 값).
    ///         0은 텍스처의 가장 왼쪽, 1은 가장 오른쪽을 의미
    ///   - y: 사각형의 **왼쪽 상단 Y 좌표** (0~1 사이 값).
    ///         RealityKit 규약에 따라 **위쪽에서 아래쪽으로 증가**
    ///   - width: 사각형의 **너비** (0~1 사이 비율).
    ///            예를 들어 0.5면 전체 텍스처의 가로 절반을 의미
    ///   - height: 사각형의 **높이** (0~1 사이 비율).
    ///             예를 들어 0.5면 전체 텍스처의 세로 절반을 의미
    init(x: Float = 0, y: Float = 0, width: Float = 1.0, height: Float = 1.0) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    
    /// 전체 UV 영역을 의미 (0,0,1,1)
    static let unit = UVRect()
    
    /// RealityKit에 넘길 offset
    public var rkOffset: SIMD2<Float> { SIMD2<Float>(x, y) }
    
    /// RealityKit에 넘길 scale (그대로 width/height)
    public var rkScale: SIMD2<Float> { SIMD2<Float>(width, height) }
    
    /// 값들을 UV 0~1 범위로 보정
    /// - Note: x,y는 [0,1], width,height는 0 이상이며 `x+width`, `y+height`가 1을 넘지 않도록 잘라냄
    /// - Returns: 보정된 UVRect
    func clamped() -> UVRect {
        var r = self
        r.x = max(0, min(1, r.x))
        r.y = max(0, min(1, r.y))
        r.width  = max(0, min(1 - r.x, r.width))
        r.height = max(0, min(1 - r.y, r.height))
        return r
    }
    
    /// 기존 UV 영역(self) 안에서, 또 한 번의 크롭(inner)을 적용한 결과를 반환
    /// 예를 들어:
    /// - `self = (0.2, 0.1, 0.5, 0.5)` 이면, 원본 텍스처의 가운데 일부분을 의미하고
    /// - `inner = (0.5, 0, 0.5, 1)` 이면, 그 영역의 **오른쪽 절반**만 다시 잘라내는 것을 의미
    /// - Parameter inner: `self` 영역을 (0~1) 로 정규화한 로컬 UV 공간에서의 크롭 영역
    /// - Returns: 원본 텍스처(전체 UV 공간) 기준으로 합성된 최종 크롭 영역
    func composed(with inner: UVRect) -> UVRect {
        let ix = inner.clamped()
        return UVRect(
            x:      x + ix.x * width,
            y:      y + ix.y * height,
            width:  width  * ix.width,
            height: height * ix.height
        )
    }
}

// MARK: - UVRect+RealityKit

@available(visionOS 2.0, iOS 18.0, *)
extension UVRect {
    /// RealityKit TextureCoordinateTransform → UVRect 역변환
    /// - Parameter t: RealityKit의 `MaterialParameterTypes.TextureCoordinateTransform`
    /// - Returns: UVRect(0~1 범위)
    public static func fromRK(_ t: MaterialParameterTypes.TextureCoordinateTransform) -> UVRect {
        let uvX = t.offset.x
        let uvY = t.offset.y
        return UVRect(x: uvX, y: uvY, width: t.scale.x, height: t.scale.y).clamped()
    }
}
