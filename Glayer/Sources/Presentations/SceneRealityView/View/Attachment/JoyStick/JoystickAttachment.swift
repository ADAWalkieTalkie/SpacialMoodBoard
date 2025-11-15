import SwiftUI

struct JoystickAttachment: View {
    
    // MARK: - Properties
    
    /// 조이스틱 값이 변경될 때 호출되는 콜백
    /// - Parameters:
    ///   - x: X축 값 (-1.0 ~ 1.0)
    ///   - z: Z축 값 (-1.0 ~ 1.0)
    private let onValueChanged: (Double, Double) -> Void
    
    @State private var thumbstickOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    // 조이스틱 크기 설정
    private let baseSize: CGFloat = 200
    private let thumbstickSize: CGFloat = 80
    private let maxDistance: CGFloat // 원형 범위의 최대 반지름
    
    // MARK: - Init
    
    init(onValueChanged: @escaping (Double, Double) -> Void) {
        self.onValueChanged = onValueChanged
        // baseSize의 절반에서 thumbstickSize의 절반을 뺀 값이 최대 이동 거리
        self.maxDistance = (baseSize - thumbstickSize) / 2
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 배경 원 (큰 회색 원)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: baseSize, height: baseSize)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Thumbstick (작은 어두운 회색 원)
            Circle()
                .fill(Color.gray.opacity(0.7))
                .frame(width: thumbstickSize, height: thumbstickSize)
                .offset(thumbstickOffset)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .frame(width: baseSize, height: baseSize)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    updateThumbstickPosition(from: value.location)
                }
                .onEnded { _ in
                    // 제스처 종료 시 중앙으로 복귀
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        thumbstickOffset = .zero
                    }
                    isDragging = false
                    // 중앙 위치 = (0, 0) 출력
                    onValueChanged(0, 0)
                }
        )
    }
    
    // MARK: - Methods
    
    /// 드래그 위치에 따라 thumbstick 위치를 업데이트하고 값을 계산
    private func updateThumbstickPosition(from location: CGPoint) {
        // 조이스틱 중심점 기준으로 변환
        let center = CGPoint(x: baseSize / 2, y: baseSize / 2)
        let relativeLocation = CGPoint(
            x: location.x - center.x,
            y: location.y - center.y
        )
        
        // 원형 범위 내로 제한
        let distance = sqrt(relativeLocation.x * relativeLocation.x + relativeLocation.y * relativeLocation.y)
        let clampedDistance = min(distance, maxDistance)
        
        // 각도 계산
        let angle = atan2(relativeLocation.y, relativeLocation.x)
        
        // 제한된 거리로 위치 계산
        let clampedX = cos(angle) * clampedDistance
        let clampedY = sin(angle) * clampedDistance
        
        // thumbstick 위치 업데이트
        thumbstickOffset = CGSize(width: clampedX, height: clampedY)
        
        // 정규화된 값 계산 (-1.0 ~ 1.0)
        let normalizedX = clampedX / maxDistance
        let normalizedZ = -clampedY / maxDistance // Y축을 Z축으로 매핑 (위쪽이 +1)
        
        // 값 출력
        print("조이스틱 값 - X: \(String(format: "%.2f", normalizedX)), Z: \(String(format: "%.2f", normalizedZ))")
        
        // 콜백 호출
        onValueChanged(normalizedX, normalizedZ)
    }
}

#Preview {
    JoystickAttachment { x, z in
        print("X: \(x), Z: \(z)")
    }
    .padding()
}
