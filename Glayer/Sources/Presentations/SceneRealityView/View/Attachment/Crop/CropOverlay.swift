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
    
    private let baseLineWidth: CGFloat = 10.0
    private var actualLineWidth: CGFloat {
        let s = max(scaleX, scaleY)
        guard s > 0 else { return baseLineWidth }
        return baseLineWidth / s
    }
    
    @State private var dragStartRect: CGRect = .zero
    @State private var activeCorner: Corner?
    @State private var dragMode: DragMode?
    
    enum DragMode {
        case corner(Corner)
        case move
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                let L = cornerLength(for: cropRect.size)
                
                ForEach(Corner.allCases, id: \.self) { corner in
                    let center = cornerCenter(corner, L: L, W: actualLineWidth)

                    let isGlowing: Bool = {
                        switch dragMode {
                        case .move:
                            return true
                        case .corner(let active):
                            return active == corner
                        default:
                            return false
                        }
                    }()

                    ZStack {
                        if isGlowing {
                            CornerBracket(length: L, lineWidth: actualLineWidth, cornerRadius: 30)
                                .foregroundStyle(.white)
                                .blur(radius: 8)
                                .shadow(
                                    color: .white.opacity(0.5),
                                    radius: 30,
                                    x: 0,
                                    y: 0
                                )
                        }

                        CornerBracket(length: L, lineWidth: actualLineWidth, cornerRadius: 30)
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
        return L * 0.5
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

// MARK: - 드래그 제스처 (코너 리사이즈 + 전체 이동)

extension CropOverlay {
    private func resizeGesture(in frameSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                let L = cornerLength(for: cropRect.size)
                
                if dragStartRect == .zero {
                    dragStartRect = cropRect
                    
                    if let corner = closestCorner(
                        point: gesture.startLocation,
                        L: L,
                        hitPadding: 0
                    ) {
                        activeCorner = corner
                        dragMode = .corner(corner)
                    } else if cropRect.contains(gesture.startLocation) {
                        activeCorner = nil
                        dragMode = .move
                    } else {
                        dragMode = nil
                        return
                    }
                }
                
                guard let dragMode else { return }
                
                let dx = gesture.translation.width
                let dy = gesture.translation.height
                
                switch dragMode {
                case .corner(let corner):
                    resizeFromCorner(corner: corner, dx: dx, dy: dy)
                    
                case .move:
                    moveWholeRect(dx: dx, dy: dy)
                }
            }
            .onEnded { _ in
                dragStartRect = .zero
                dragMode = nil
                activeCorner = nil
            }
    }
    
    // MARK: - 코너 리사이즈

    private func resizeFromCorner(corner: Corner, dx: CGFloat, dy: CGFloat) {
        let start = dragStartRect
        
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
    
    // MARK: - 전체 이동

    private func moveWholeRect(dx: CGFloat, dy: CGFloat) {
        var newRect = dragStartRect.offsetBy(dx: dx, dy: dy)
        
        let minX = imageFrame.minX
        let maxX = imageFrame.maxX - newRect.width
        let minY = imageFrame.minY
        let maxY = imageFrame.maxY - newRect.height
        
        newRect.origin.x = min(max(newRect.origin.x, minX), maxX)
        newRect.origin.y = min(max(newRect.origin.y, minY), maxY)
        
        cropRect = newRect
    }
}
