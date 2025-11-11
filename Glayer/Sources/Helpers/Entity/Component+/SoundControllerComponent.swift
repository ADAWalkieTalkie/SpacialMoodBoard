//
//  SoundControllerComponent.swift
//  Glayer
//
//  Created by jeongminji on 10/29/25.
//

import RealityKit

/// 오디오 재생 제어용 컨트롤러를 Entity에 붙여두기 위한 컴포넌트
/// - `controller`: 재생/일시정지/정지, gain(dB) 조절을 담당하는 AudioPlaybackController 보관
struct SoundControllerComponent: Component {
    var controller: AudioPlaybackController?
}
