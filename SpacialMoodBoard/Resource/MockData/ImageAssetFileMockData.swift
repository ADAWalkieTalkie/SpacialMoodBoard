import Foundation

// MARK: - ImageAssetFile Mock Data

extension Asset {
    static let assetMockData: [Asset] = [
        Asset(
            id: UUID(), 
            type: .image,
            filename: "JackJump",
            mime: "image/png",
            filesize: 1000,
            url: URL(string: "https://example.com/image1.png")!,
            createdAt: Date(),
            image: ImageAsset(width: 1024, height: 1267)
        ),

        Asset(id: UUID(),
            type: .image,
            filename: "goldfish",
            mime: "image/png",
            filesize: 1000,
            url: URL(string: "https://example.com/image2.png")!,
            createdAt: Date(),
            image: ImageAsset(width: 1024, height: 1267)
        ),
    ]
}

extension SceneObject {
    static let sceneObjectMockData: [SceneObject] = [
        SceneObject.createImage(
            assetId: Asset.assetMockData[0].id
        ),
        SceneObject.createImage(
            assetId: Asset.assetMockData[1].id
        ),
    ]
}