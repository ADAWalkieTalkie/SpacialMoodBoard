//
//  String+.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import Foundation

extension String {
    /// NSString 의 deletingPathExtension API를 빌려서, "Astronaut.png" → "Astronaut" 처럼 마지막 점(.) 뒤 확장자만 제거
    var deletingPathExtension: String { (self as NSString).deletingPathExtension }
}
