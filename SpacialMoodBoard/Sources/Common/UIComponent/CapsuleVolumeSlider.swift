//
//  CapsuleVolumeSlider.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import SwiftUI

struct CapsuleVolumeSlider: View {
    
    // MARK: - Properties
    
    @Binding private var value: Double
    private var onEditingChanged: ((Bool)->Void)? = nil
    
    private var trackHeight: CGFloat
    private var thumbDiameter: CGFloat
    private var backgroundColor: Color
    private var fillColor: Color
    private var thumbColor: Color
    
    @State private var isEditing = false
    
    // MARK: - Init
    
    /// 커스텀 캡슐 형태 슬라이더 초기화
    /// - Parameters:
    ///   - value: 0...1 범위의 슬라이더 값. 외부 상태와 양방향 바인딩됨
    ///   - onEditingChanged: 사용자가 슬라이더를 드래그하거나 놓을 때 호출되는 콜백 (true = 드래그 중, false = 종료)
    ///   - trackHeight: 슬라이더 트랙(막대)의 높이. 기본값은 2
    ///   - thumbDiameter: 손잡이(원)의 지름. 기본값은 12
    ///   - backgroundColor: 비활성(남은 구간) 트랙 색상
    ///   - fillColor: 활성(채워진 구간) 트랙 색상
    ///   - thumbColor: 손잡이 색상
    init(
        value: Binding<Double>,
        onEditingChanged: ((Bool)->Void)? = nil,
        trackHeight: CGFloat = 2,
        thumbDiameter: CGFloat = 16,
        backgroundColor: Color = .white.opacity(0.25),
        fillColor: Color = .white.opacity(0.6),
        thumbColor: Color = .white
    ) {
        self._value = value
        self.onEditingChanged = onEditingChanged
        self.trackHeight = trackHeight
        self.thumbDiameter = thumbDiameter
        self.backgroundColor = backgroundColor
        self.fillColor = fillColor
        self.thumbColor = thumbColor
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clamped = value.clamped(to: 0...1)
            
            ZStack(alignment: .leading) {
                // 트랙(전체)
                Capsule()
                    .fill(backgroundColor)
                    .frame(height: trackHeight)
                
                // 채워진 구간
                Capsule()
                    .fill(fillColor)
                    .frame(width: max(thumbDiameter/2, clamped * (width - thumbDiameter) + thumbDiameter/2),
                           height: trackHeight)
                
                // 손잡이
                Circle()
                    .fill(thumbColor)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .shadow(radius: 0.5)
                    .offset(x: clamped * (width - thumbDiameter))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                if !isEditing {
                                    isEditing = true
                                    onEditingChanged?(true)
                                }
                                let x = g.location.x - thumbDiameter/2
                                let newVal = Double(x / (width - thumbDiameter)).clamped(to: 0...1)
                                withAnimation(.easeOut(duration: 0.06)) {
                                    value = newVal
                                }
                                onEditingChanged?(true)
                            }
                            .onEnded { _ in
                                isEditing = false
                                onEditingChanged?(false)
                            }
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture { loc in
                let x = loc.x - thumbDiameter/2
                let newVal = Double(x / (width - thumbDiameter)).clamped(to: 0...1)
                withAnimation(.easeOut(duration: 0.08)) { value = newVal }
                onEditingChanged?(false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Volume")
            .accessibilityValue("\(Int(value * 100)) percent")
        }
        .frame(height: max(trackHeight, thumbDiameter))
    }
}

private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}
