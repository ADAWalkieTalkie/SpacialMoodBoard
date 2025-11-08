import Foundation

/// 리셋과 취소가 가능한 간단한 타이머
@MainActor
final class Timer {
    
    // MARK: - Properties
    
    /// 타이머 지속 시간 (초)
    private let duration: TimeInterval
    
    /// 타이머 Task
    private var timerTask: Task<Void, Never>?
    
    /// 타이머 완료 시 실행될 클로저
    private var onComplete: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Timer 초기화
    /// - Parameters:
    ///   - duration: 타이머 지속 시간 (초)
    ///   - onComplete: 타이머 완료 시 실행될 클로저
    init(duration: TimeInterval, onComplete: (() -> Void)? = nil) {
        self.duration = duration
        self.onComplete = onComplete
    }
    
    // MARK: - Public Methods
    
    /// 타이머 시작
    func start() {
        guard timerTask == nil else { return }
        
        timerTask = Task { [weak self] in
            guard let self else { return }
            
            let nanoseconds = UInt64(self.duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            
            guard !Task.isCancelled else { return }
            
            await self.complete()
        }
    }
    
    /// 타이머를 처음으로 리셋하고 시작
    func reset() {
        cancel()
        start()
    }
    
    /// 타이머 멈추기 (취소)
    func cancel() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    /// 타이머 완료 시 실행될 클로저 설정
    func setOnComplete(_ handler: @escaping () -> Void) {
        self.onComplete = handler
    }
    
    // MARK: - Private Methods
    
    private func complete() {
        timerTask = nil
        onComplete?()
    }
    
    deinit {
        cancel()
    }
}