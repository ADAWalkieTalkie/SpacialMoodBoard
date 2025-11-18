//
//  GuidingToastMessage.swift
//  Glayer
//
//  Created by jeongminji on 11/18/25.
//

import Foundation

enum GuidingToastMessage {
    case imageEdit
    case assetPlacement
    
    var steps: [GuidingToastModel] {
        switch self {
        case .imageEdit:
            return [
                .init(
                    title: String(localized: "guiding.imageEdit.removeBackground.title"),
                    description: String(localized: "guiding.imageEdit.removeBackground.description"),
                    videoName: "RemoveImageBg"
                ),
                .init(
                    title: String(localized: "guiding.imageEdit.keepAsIs.title"),
                    description: String(localized: "guiding.imageEdit.keepAsIs.description"),
                    videoName: "ImageAddDirectly"
                ),
                .init(
                    title: String(localized: "guiding.imageEdit.finish.title"),
                    description: String(localized: "guiding.imageEdit.finish.description"),
                    videoName: "ImageEditDone"
                )
            ]
            
        case .assetPlacement:
            return [
                .init(
                    title: String(localized: "guiding.assetPlacement.place.title"),
                    description: String(localized: "guiding.assetPlacement.place.description"),
                    videoName: "SceneObjectPosition"
                ),
                .init(
                    title: String(localized: "guiding.assetPlacement.rotate.title"),
                    description: String(localized: "guiding.assetPlacement.rotate.description"),
                    videoName: "SceneObjectRotate"
                ),
                .init(
                    title: String(localized: "guiding.assetPlacement.scale.title"),
                    description: String(localized: "guiding.assetPlacement.scale.description"),
                    videoName: "SceneObjectScale"
                )
            ]
        }
    }
}
