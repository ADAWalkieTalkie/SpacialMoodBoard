//
//  Asset.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/12/25.
//

import Foundation

struct Asset: Identifiable, Hashable, Codable {
    let id: UUID
    var type: AssetType
    var filename: String              // 초기 원본 파일명 -> 사용자 변경 가능
    var mime: String?                 // ex) "image/png", "audio/mpeg"
    var filesize: Int?                // byte
    var url: URL                      // 실제 파일 위치
    var createdAt: Date

    // 1:0..1
    var image: ImageAsset?


}
