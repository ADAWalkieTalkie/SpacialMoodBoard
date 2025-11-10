//
//  ToastDismissMode.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/8/25.
//

import Foundation

enum ToastDismissMode {
    case auto(duration: TimeInterval)
    case manual
    case external(shouldDismiss: (() -> Bool)? = nil)
}
