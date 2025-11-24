//
//  CropOverlay.swift
//  Glayer
//
//  Created by jeongminji on 11/13/25.
//

import SwiftUI

struct CropOverlay: View {
    
    // MARK: - Properties
    
    @Binding var cropRect: CGRect
    let scaleX: CGFloat
    let scaleY: CGFloat
    let imageFrame: CGRect
    
    private let baseLineWidth: CGFloat = 8.0
    private var actualLineWidth: CGFloat {
        let s = max(scaleX, scaleY)
        guard s > 0 else { return baseLineWidth }
        return baseLineWidth / s
    }
    
    @State private var dragStartRect: CGRect = .zero
    @State private var activeCorner: Corner?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                Path { path in
                    path.addRect(imageFrame)
                    path.addRect(cropRect)
                }
                .fill(
                    Color.black.opacity(0.4),
                    style: FillStyle(eoFill: true)
                )
                .allowsHitTesting(false)
                
                let L = cornerLength(for: cropRect.size)
                
                ForEach(Corner.allCases, id: \.self) { corner in
                    let center = cornerCenter(corner, L: L, W: actualLineWidth)
                    
                    ZStack {
                        if activeCorner == corner {
                            CornerBracket(length: L, lineWidth: actualLineWidth)
                                .foregroundStyle(.white)
                                .blur(radius: 8)
                                .shadow(
                                    color: .white.opacity(0.5),
                                    radius: 30,
                                    x: 0,
                                    y: 0
                                )
                        }
                        
                        CornerBracket(length: L, lineWidth: actualLineWidth)
                            .foregroundStyle(.white)
                    }
                    .rotationEffect(angle(for: corner))
                    .position(center)
                    .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(resizeGesture(in: geo.size))
        }
    }
}

// MARK: - 코너 길이 계산

extension CropOverlay {
    func cornerLength(for size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 0 }
        
        let shortSide = min(size.width, size.height)
        let padding = shortSide / 3.0
        
        let horizontalCandidate = max(0, (size.width  - padding) / 2)
        let verticalCandidate   = max(0, (size.height - padding) / 2)
        
        let L = min(horizontalCandidate, verticalCandidate)
        return L
    }
}

// MARK: - 코너 위치 / 회전

extension CropOverlay {
    enum Corner: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    func cornerCenter(_ corner: Corner, L: CGFloat, W: CGFloat) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(
                x: cropRect.minX + (L + W) / 2,
                y: cropRect.minY + (L + W) / 2
            )
        case .topRight:
            return CGPoint(
                x: cropRect.maxX - (L + W) / 2,
                y: cropRect.minY + (L + W) / 2
            )
        case .bottomLeft:
            return CGPoint(
                x: cropRect.minX + (L + W) / 2,
                y: cropRect.maxY - (L + W) / 2
            )
        case .bottomRight:
            return CGPoint(
                x: cropRect.maxX - (L + W) / 2,
                y: cropRect.maxY - (L + W) / 2
            )
        }
    }

    func angle(for corner: Corner) -> Angle {
        switch corner {
        case .topLeft:     return .degrees(0)
        case .topRight:    return .degrees(90)
        case .bottomRight: return .degrees(180)
        case .bottomLeft:  return .degrees(270)
        }
    }
}

// MARK: - 어떤 코너를 터치했는지 찾기 (Medium 스타일)

extension CropOverlay {
    private func closestCorner(point: CGPoint, L: CGFloat, hitPadding: CGFloat = 0) -> Corner? {
        let size = L + hitPadding * 2
        let half = size / 2
        
        func rect(for corner: Corner) -> CGRect {
            let center = cornerCenter(corner, L: L, W: actualLineWidth)
            return CGRect(
                x: center.x - half,
                y: center.y - half,
                width: size,
                height: size
            )
        }
        
        if rect(for: .topLeft).contains(point)    { return .topLeft }
        if rect(for: .topRight).contains(point)   { return .topRight }
        if rect(for: .bottomLeft).contains(point) { return .bottomLeft }
        if rect(for: .bottomRight).contains(point){ return .bottomRight }
        
        return nil
    }
}

// MARK: - 드래그 제스처 (한 번만 붙이고, 안에서 코너 분기)

extension CropOverlay {
    private func resizeGesture(in frameSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                let L = cornerLength(for: cropRect.size)
                if dragStartRect == .zero {
                    dragStartRect = cropRect
                    activeCorner = closestCorner(
                        point: gesture.startLocation,
                        L: L,
                        hitPadding: 0
                    )
                }
                
                guard let corner = activeCorner else { return }
                
                let start = dragStartRect
                let dx = gesture.translation.width
                let dy = gesture.translation.height
                
                var newMinX = start.minX
                var newMaxX = start.maxX
                var newMinY = start.minY
                var newMaxY = start.maxY
                
                switch corner {
                case .topLeft:
                    newMinX = start.minX + dx
                    newMinY = start.minY + dy
                    
                case .topRight:
                    newMaxX = start.maxX + dx
                    newMinY = start.minY + dy
                    
                case .bottomLeft:
                    newMinX = start.minX + dx
                    newMaxY = start.maxY + dy
                    
                case .bottomRight:
                    newMaxX = start.maxX + dx
                    newMaxY = start.maxY + dy
                }
                
                let minSize: CGFloat = 10
                
                newMinX = max(imageFrame.minX, min(newMinX, imageFrame.maxX - minSize))
                newMaxX = min(imageFrame.maxX, max(newMaxX, imageFrame.minX + minSize))
                
                if newMaxX - newMinX < minSize {
                    if corner == .topLeft || corner == .bottomLeft {
                        newMinX = newMaxX - minSize
                    } else {
                        newMaxX = newMinX + minSize
                    }
                }
                
                newMinY = max(imageFrame.minY, min(newMinY, imageFrame.maxY - minSize))
                newMaxY = min(imageFrame.maxY, max(newMaxY, imageFrame.minY + minSize))
                
                if newMaxY - newMinY < minSize {
                    if corner == .topLeft || corner == .topRight {
                        newMinY = newMaxY - minSize
                    } else {
                        newMaxY = newMinY + minSize
                    }
                }
                
                cropRect = CGRect(
                    x: newMinX,
                    y: newMinY,
                    width: newMaxX - newMinX,
                    height: newMaxY - newMinY
                )
            }
            .onEnded { _ in
                dragStartRect = .zero
                activeCorner = nil
            }
    }
}
