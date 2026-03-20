import Foundation

// NotificationCenter 기반 제스처 이벤트 전파 제거로 현재 확장 포인트는 비워둡니다.
import Foundation

// MARK: - Notification Names

extension Notification.Name {
    /// Entity gesture 종료 시 attachment 회전 업데이트를 위한 notification
    static let entityGestureUpdated = Notification.Name("entityGestureUpdated")
}