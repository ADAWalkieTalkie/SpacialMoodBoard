//
//  SoundAsset.swift
//  Glayer
//
//  Created by jeongminji on 10/21/25.
//

import Foundation

struct SoundAsset: Hashable, Codable {
    var origin: SoundOrigin
    var channel: SoundChannel
    var duration: TimeInterval
    
    /// 0...1 로 정규화된 파형 (막대용)
    var waveform: [Float] = []
}
