//
//  SoundFX.swift
//  Glayer
//
//  Created by jeongminji on 11/6/25.
//

import Foundation
import AVFoundation

/// 앱 전역에서 간단한 UI 사운드 이펙트를 재생하기 위한 싱글톤 클래스
/// - 여러 `AVAudioPlayer` 인스턴스를 풀(Pool)로 관리하여 동일 사운드를 겹쳐 재생 가능
/// - 카테고리는 `.ambient` 로 설정되어 시스템 음악을 방해하지 않음
final class SoundFX {
    
    // MARK: - Properties
    
    static let shared = SoundFX()
    
    private var pool: [SFX: [AVAudioPlayer]] = [:]
    private let poolSize = 3
    
    // MARK: - Init
    
    /// 오디오 세션을 `.ambient` 로 설정하여 앱 외부 음악과 함께 재생 가능하게 초기화
    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Methods
    
    /// 지정된 사운드 효과 재생
    ///  - Parameters:
    ///    - sfx: 재생할 사운드 이펙트(`SFX` 열거형 값)
    ///    - volume: 재생 볼륨 (0.0~1.0, 기본값 1.0)
    ///
    ///  내부적으로 다음 로직으로 동작
    ///  1. 풀에 해당 사운드가 없으면 `preload(_:)` 로 미리 로드
    ///  2. 재생 중이지 않은 플레이어를 찾아 재사용
    ///  3. 모두 재생 중이면 새로운 플레이어를 만들어 추가 (단, `poolSize` 제한)
    func play(_ sfx: SFX, volume: Float = 1.0) {
        if pool[sfx] == nil { preload(sfx) }
        guard var players = pool[sfx] else { return }
        
        if let idle = players.first(where: { !$0.isPlaying }) {
            idle.volume = volume
            idle.currentTime = 0
            idle.play()
            return
        }
        
        if players.count < poolSize, let p = makePlayer(for: sfx) {
            p.volume = volume
            p.play()
            players.append(p)
            pool[sfx] = players
        }
    }
    
    // MARK: - Private Methods
    
    /// 지정된 사운드에 대한 `AVAudioPlayer` 인스턴스 미리 로드
    /// - Parameter sfx: 미리 로드할 사운드 타입
    private func preload(_ sfx: SFX) {
        var players: [AVAudioPlayer] = []
        for _ in 0..<poolSize {
            if let p = makePlayer(for: sfx) {
                p.prepareToPlay()
                players.append(p)
            }
        }
        pool[sfx] = players
    }
    
    /// 사운드 파일을 기반으로 `AVAudioPlayer` 인스턴스를 생성
    /// - Parameter sfx: 로드할 사운드 타입
    /// - Returns: 생성된 `AVAudioPlayer` 또는 로드 실패 시 `nil`
    private func makePlayer(for sfx: SFX) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav") else {
            print("⚠️ SFX not found:", sfx.rawValue)
            return nil
        }
        return try? AVAudioPlayer(contentsOf: url)
    }
}
