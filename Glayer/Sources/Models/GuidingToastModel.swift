//
//  GuidingToastModel.swift
//  Glayer
//
//  Created by jeongminji on 11/18/25.
//

struct GuidingToastModel {
    let title: String
    let description: String
    let videoName: String
    
    init(
        title: String,
        description: String,
        videoName: String
    ) {
        self.title = title
        self.description = description
        self.videoName = videoName
    }
}
