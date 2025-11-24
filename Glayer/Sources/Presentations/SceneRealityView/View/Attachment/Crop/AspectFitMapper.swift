//
//  AspectFitMapper.swift
//  Glayer
//
//  Created by jeongminji on 11/13/25.
//

import CoreGraphics

struct AspectFitMapper {
    // MARK: - Properties
    
    let viewSize: CGSize
    let imageSize: CGSize
    
    /// `imageSize` 이미지를 `viewSize` 안에 `aspectFit`으로 배치했을 때
    /// 실제로 화면에서 이미지를 차지하게 되는 영역(Rect)
    ///
    /// - 가로가 더 긴 이미지면: 가로를 view 폭에 맞추고, 위·아래에 레터박스(여백)를 둠
    /// - 세로가 더 긴 이미지면: 세로를 view 높이에 맞추고, 좌·우에 레터박스를 둠
    var fittedRect: CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect  = viewSize.width / viewSize.height
        
        if imageAspect > viewAspect {
            let width  = viewSize.width
            let height = width / imageAspect
            let x: CGFloat = 0
            let y: CGFloat = (viewSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        } else {
            let height = viewSize.height
            let width  = height * imageAspect
            let x: CGFloat = (viewSize.width - width) / 2
            let y: CGFloat = 0
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }

    // MARK: - Methods
    
    /// View 좌표계의 사각형(rect)을 이미지 UV(0~1) 좌표로 변환
    /// - Parameters:
    ///   - rect: 화면(View) 상에서의 크롭 영역.
    ///           이미지 바깥의 여백까지 포함 가능
    /// - Returns:
    ///   `imageSize`를 기준으로 한 UVRect (0~1 범위)
    ///   만약 `rect`가 레터박스 영역까지 포함되어 있으면,
    ///   실제 이미지가 차지하는 영역(`fittedRect`)과의 교집합만 사용하여  UV 계산
    func viewRectToUV(_ rect: CGRect) -> UVRect {
        let fitted = fittedRect
        guard fitted.width > 0, fitted.height > 0 else {
            return UVRect()
        }
        let inter = rect.intersection(fitted)

        let x = (inter.origin.x - fitted.origin.x) / fitted.width
        let y = (inter.origin.y - fitted.origin.y) / fitted.height
        let w = inter.size.width / fitted.width
        let h = inter.size.height / fitted.height

        return UVRect(
            x: Float(x),
            y: Float(y),
            width:  Float(w),
            height: Float(h)
        )
    }

    /// 이미지 UV(0~1) 크롭 정보를 View 좌표계의 사각형(rect)으로 변환
    /// - Parameters:
    ///   - uv: 원본 이미지 기준의 UVRect (0~1 범위)
    /// - Returns:
    ///   현재 View 안에서, `aspectFit` 되어 배치된 이미지 영역(`fittedRect`) 위에
    ///   해당 UV가 차지하게 될 실제 View 좌표계의 사각형(`CGRect`)
    func uvToViewRect(_ uv: UVRect) -> CGRect {
        let fitted = fittedRect

        let x = fitted.origin.x + CGFloat(uv.x) * fitted.width
        let y = fitted.origin.y + CGFloat(uv.y) * fitted.height
        let w = CGFloat(uv.width)  * fitted.width
        let h = CGFloat(uv.height) * fitted.height

        return CGRect(x: x, y: y, width: w, height: h)
    }
}
