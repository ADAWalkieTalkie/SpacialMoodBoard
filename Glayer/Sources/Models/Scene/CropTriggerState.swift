//
//  CropTriggerState.swift
//  Glayer
//
//  Created by PenguinLand on 1/9/26.
//

import Foundation
import Observation

/// CropAttachment의 외부 트리거 상태를 관리하는 Observable 객체
///
/// Crop UI와 Control UI 간의 상태 동기화를 위해 사용됨
/// - `shouldComplete`: 크롭 완료 트리거
/// - `shouldCancel`: 크롭 취소 트리거
@Observable
class CropTriggerState {
    var shouldComplete: Bool = false
    var shouldCancel: Bool = false
}
