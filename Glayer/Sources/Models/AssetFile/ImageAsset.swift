//
//  ImageAsset.swift
//  Glayer
//
//  Created by jeongminji on 10/12/25.
//

struct ImageAsset: Codable, Hashable {
    let width: Int
    let height: Int
    
    var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }
}
