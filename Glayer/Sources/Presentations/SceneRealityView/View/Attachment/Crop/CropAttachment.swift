//
//  CropAttachment.swift
//  Glayer
//
//  Created by jeongminji on 11/13/25.
//

import SwiftUI
import RealityKit
import Observation

/// CropAttachment의 외부 트리거 상태를 관리하는 Observable 객체
@Observable
class CropTriggerState {
    var shouldComplete: Bool = false
    var shouldCancel: Bool = false
}

struct CropAttachment: View {
    
    // MARK: - Properties
    
    let image: UIImage
    let initialUV: UVRect
    let scaleX: CGFloat?
    let scaleY: CGFloat?
    let onDone: (UVRect) -> Void

    @State private var cropRect: CGRect = .zero
    @State private var viewSize: CGSize = .zero
    @State private var imageFrame: CGRect = .zero
    @State private var didComplete = false
    var triggerState: CropTriggerState
    
    /// 실제로 화면에 깔릴 이미지
    /// - initialUV가 전체(0,0,1,1)이면 원본 그대로
    /// - 아니면 initialUV 영역만 잘라낸 서브 이미지
    private var displayImage: UIImage {
        let uv = initialUV.clamped()
        
        let isFull =
        abs(uv.x) < 0.0001 &&
        abs(uv.y) < 0.0001 &&
        abs(uv.width - 1) < 0.0001 &&
        abs(uv.height - 1) < 0.0001
        
        guard !isFull, let cg = image.cgImage else {
            return image
        }
        
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        
        let cropRectPx = CGRect(
            x: CGFloat(uv.x) * w,
            y: CGFloat(uv.y) * h,
            width: CGFloat(uv.width) * w,
            height: CGFloat(uv.height) * h
        ).intersection(CGRect(x: 0, y: 0, width: w, height: h))
        
        guard
            cropRectPx.width > 0,
            cropRectPx.height > 0,
            let croppedCG = cg.cropping(to: cropRectPx)
        else {
            return image
        }
        
        return UIImage(
            cgImage: croppedCG,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Image(uiImage: displayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.6)
                .overlay(overlayView)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                viewSize = geo.size
                                let mapper = AspectFitMapper(
                                    viewSize: geo.size,
                                    imageSize: displayImage.size
                                )
                                let fitted = mapper.fittedRect
                                imageFrame = fitted
                                                               
                                let full = UVRect(x: 0, y: 0, width: 1, height: 1)
                                cropRect = mapper.uvToViewRect(full)
                            }
                    }
                )
        }
        .frame(width: 1000)
        .aspectRatio(displayImage.size, contentMode: .fit)
        .background(.clear)
        .onChange(of: triggerState.shouldComplete) { oldValue, newValue in
            if newValue && !didComplete {
                complete()
            }
        }
    }
    
    // MARK: - Methods
    
    
    /// SwiftUI 위에서만 '크롭된 영역 강조 + 코너 드래그 UI'를 구성하기 위한 전용 레이어
    /// 구성:
    /// 1) `displayImage`를 그대로 사용하지만 `cropRect` 영역만 보이도록 `mask` 처리한 레이어
    ///    - 크롭된 부분만 100% 불투명하게 선명하게 보이게 함
    /// 2) `CropOverlay`
    ///    - 코너 브래킷(드래그 핸들)과 드래그 제스처를 담당하는 오버레이
    ///    - 이미지 좌표계(imageFrame) 기준으로 cropRect를 직접 조작
    @ViewBuilder
    private var overlayView: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: displayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .mask(
                    CropMaskShape(rect: cropRect, cornerRadius: 30)
                )
            
            if let sx = scaleX, let sy = scaleY {
                CropOverlay(
                    cropRect: $cropRect,
                    scaleX: sx,
                    scaleY: sy,
                    imageFrame: imageFrame
                )
            }
        }
    }
    
    /// 현재까지 사용자가 조작한 크롭 결과를 UVRect로 변환하여 콜백으로 전달
    private func complete() {
        guard !didComplete else { return }
        didComplete = true
        
        guard viewSize != .zero else {
            onDone(initialUV.clamped())
            return
        }
        
        let mapper = AspectFitMapper(
            viewSize: viewSize,
            imageSize: displayImage.size
        )
        let innerUV = mapper.viewRectToUV(cropRect).clamped()
        let finalUV = initialUV.clamped().composed(with: innerUV).clamped()
        
        onDone(finalUV)
    }

    /// 현재 크롭 상태를 UVRect로 변환하여 반환 (완료하지 않고 조회만)
    /// CropControlAttachment의 완료 버튼에서 호출됨
    func getCurrentUV() -> UVRect {
        guard viewSize != .zero else {
            return initialUV.clamped()
        }

        let mapper = AspectFitMapper(
            viewSize: viewSize,
            imageSize: displayImage.size
        )
        let innerUV = mapper.viewRectToUV(cropRect).clamped()
        return initialUV.clamped().composed(with: innerUV).clamped()
    }
}

/// cropRect 영역만 보이게 마스크하는 Shape
struct CropMaskShape: Shape {
    var rect: CGRect
    var cornerRadius: CGFloat = 0

    func path(in _: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return p
    }
}
