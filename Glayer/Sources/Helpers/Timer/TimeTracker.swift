import Foundation

/// 시간 추적을 위한 클래스 (mutable)
class TimeTracker {
    var lastUpdateTime: Date = Date()
    private var isFirstCall = true
    
    func getDeltaTime() -> Float {
        let currentTime = Date()
        let deltaTime: Float
        
        if isFirstCall {
            // 첫 번째 호출 시 deltaTime을 0으로 설정 (또는 매우 작은 값)
            deltaTime = 0.0
            isFirstCall = false
        } else {
            let timeInterval = currentTime.timeIntervalSince(lastUpdateTime)
            // deltaTime이 비정상적으로 크면 (예: 1초 이상) 무시
            deltaTime = Float(min(timeInterval, 0.1)) // 최대 0.1초로 제한
        }
        
        lastUpdateTime = currentTime
        return deltaTime
    }
}