//
//  CapsuleVolumeSlider.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/29/25.
//

import SwiftUI

struct CapsuleVolumeSlider: View {
    @Binding private var value: Double
    private let onEditingChanged: ((Bool) -> Void)?
    
    private let trackHeight: CGFloat
    private let thumbDiameter: CGFloat
    private let backgroundColor: Color
    private let fillColor: Color
    private let thumbColor: Color
    
    @State private var isDragging = false
    @State private var internalValue: Double
    @State private var trackWidth: CGFloat = 0
    
    init(
        value: Binding<Double>,
        onEditingChanged: ((Bool) -> Void)? = nil,
        trackHeight: CGFloat = 2,
        thumbDiameter: CGFloat = 16,
        backgroundColor: Color = .gray.opacity(0.25),
        fillColor: Color = .white,
        thumbColor: Color = .white
    ) {
        self._value = value
        self._internalValue = State(initialValue: value.wrappedValue)
        self.onEditingChanged = onEditingChanged
        self.trackHeight = trackHeight
        self.thumbDiameter = thumbDiameter
        self.backgroundColor = backgroundColor
        self.fillColor = fillColor
        self.thumbColor = thumbColor
    }
    
    var body: some View {
        GeometryReader { _ in
            let w = max(trackWidth, thumbDiameter)
            let usable = w - thumbDiameter
            let clamped = internalValue.clamped(to: 0...1)
            let centerX = CGFloat(clamped) * usable + thumbDiameter / 2
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(backgroundColor)
                    .frame(height: trackHeight)
                    .background(
                        GeometryReader { p in
                            Color.clear
                                .onAppear { trackWidth = p.size.width }
                                .onChange(of: p.size.width) { oldWidth, newWidth in
                                    guard newWidth > 0, newWidth != oldWidth else { return }
                                    trackWidth = newWidth
                                }
                        }
                    )
                
                Capsule()
                    .fill(fillColor)
                    .frame(width: centerX, height: trackHeight)
                
                Circle()
                    .fill(thumbColor)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .offset(x: centerX - thumbDiameter / 2)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDragging)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .contentShape(Capsule())
            .frame(maxHeight: .infinity)
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        guard trackWidth > 0 else { return }
                        if !isDragging {
                            isDragging = true
                            onEditingChanged?(true)
                        }
                        
                        let minCenter = thumbDiameter / 2
                        let maxCenter = trackWidth - thumbDiameter / 2
                        
                        let clampedCenterX = min(max(g.location.x - 10, minCenter), maxCenter)
                        
                        let newVal = Double((clampedCenterX - thumbDiameter / 2) / usable).clamped(to: 0...1)
                        internalValue = newVal
                        value = newVal
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged?(false)
                    },
                including: .all
            )
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Previews
#Preview {
    @Previewable @State var volume = 0.5
    VStack(spacing: 40) {
        CapsuleVolumeSlider(value: $volume)
            .frame(width: 100)
        Text(String(format: "Volume: %.2f", volume))
            .foregroundStyle(.white)
    }
    .padding()
    .background(.black)
}
