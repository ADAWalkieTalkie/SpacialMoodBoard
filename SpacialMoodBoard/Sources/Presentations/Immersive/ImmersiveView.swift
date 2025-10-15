//
//  ImmersiveView.swift
//  SpacialMoodBoard
//
//  Created by apple on 10/2/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(SceneModel.self) private var sceneModel

    private let assets: [Asset] = Asset.assetMockData

    // Entity 추적을 위한 딕셔너리 (State로 관리)
    @State private var entityMap: [UUID: ModelEntity] = [:]

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        } update: { content in
            // SceneObject들을 Entity로 변환하여 추가
            updateEntities(in: content)
        }
    }
    
    /// SceneObject 변경 시 Entity 업데이트
    private func updateEntities(in content: RealityViewContent) {
        // SceneObject들을 Entity로 변환하여 추가
        for sceneObject in sceneModel.sceneObjects {
            // Asset 찾기
            guard let asset = assets.first(where: { $0.id == sceneObject.assetId }) else {
                print("❌ Asset을 찾을 수 없습니다: \(sceneObject.assetId)")
                print("   사용 가능한 Asset IDs: \(assets.map { $0.id })")
                continue
            }
            // Entity 생성
            if let entity = ImageEntity.create(from: sceneObject, with: asset) {
                content.add(entity)
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(SceneModel())
}
