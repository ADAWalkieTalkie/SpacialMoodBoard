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

    // 선택된 Entity ID를 추적
    @State private var selectedEntity: ModelEntity?

    var body: some View {
        RealityView { content, attachments in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
        } update: { content, attachments in
            // SceneObject들을 Entity로 변환하여 추가
            updateEntities(in: content)

            // Attachment를 선택된 Entity에 연결
            // updateAttachment(in: content, attachments: attachments)

        } attachments: {
            // 선택된 Entity에 대한 Attachment 표시
            if let selectedEntity = selectedEntity,
               let objectId = UUID(uuidString: selectedEntity.name) {
                Attachment(id: "selectedId") {
                    ImageAttachment(
                        objectId: objectId,
                        onDuplicate: {
                            // duplicateObject(selectedEntity.id)
                            print("복사")
                        },
                        onCrop: {
                            // cropObject(selectedEntity.id)
                            print("크롭")
                        },
                        onDelete: {
                            // sceneModel.removeSceneObject(id: selectedEntity.id)
                            self.selectedEntity = nil
                        }
                    )
                    .onAppear {
                        print("AttachmentView 추가")
                    }
                }
            }
        }
        // ✨ 모든 제스처를 한 번에 적용
        .immersiveEntityGestures(
            selectedEntity: $selectedEntity,
            onPositionUpdate: { uuid, position in
                sceneModel.updateObjectPosition(id: uuid, position: position)
            }
        )
    }
    
    /// SceneObject 변경 시 Entity 업데이트
    private func updateEntities(in content: RealityViewContent) {
        let currentObjectIds = Set(sceneModel.sceneObjects.map { $0.id })
        let existingEntityIds = Set(entityMap.keys)
        
        // 1. 삭제된 객체의 Entity 제거
        for removedId in existingEntityIds.subtracting(currentObjectIds) {
            if let entity = entityMap[removedId] {
                content.remove(entity)
                // Task로 감싸서 비동기로 상태 변경
                Task { @MainActor in
                    entityMap.removeValue(forKey: removedId)
                }
            }
        }
        
        // 2. 새로운 객체 추가 또는 기존 객체 업데이트
        for sceneObject in sceneModel.sceneObjects {
            // Asset 찾기
            guard let asset = assets.first(where: { $0.id == sceneObject.assetId }) else {
                print("❌ Asset을 찾을 수 없습니다: \(sceneObject.assetId)")
                continue
            }
            
            if let existingEntity = entityMap[sceneObject.id] {
                // 기존 Entity 업데이트 (위치만)
                existingEntity.position = sceneObject.position
            } else {
                // 새 Entity 생성
                if let entity = ImageEntity.create(from: sceneObject, with: asset, viewMode: sceneModel.userSpatialState.viewMode) {
                    content.add(entity)
                    // Task로 감싸서 비동기로 상태 변경
                    Task { @MainActor in
                        entityMap[sceneObject.id] = entity
                    }
                }
            }
        }
    }
    
    /// SceneObject의 위치를 SceneModel에 업데이트
    private func updateSceneObjectPosition(id: UUID, position: SIMD3<Float>) {
        sceneModel.updateObjectPosition(id: id, position: position)
    }

    // MARK: - Attachment 관리
    
    /// Attachment를 선택된 Entity에 연결
    // private func updateAttachment(in content: RealityViewContent, attachments: RealityViewAttachments) {
    //     if let selected = selectedEntity,
    //        let attachment = attachments.entity(for: "selectedId") {
    //         // Entity 상단에 버튼 배치
    //         let bounds = selected.visualBounds(relativeTo: nil)
    //         attachment.position = selected.position + SIMD3<Float>(0, bounds.max.y, 0)
            
    //         if attachment.parent == nil {
    //             content.add(attachment)
    //         }
    //     } else {
    //         // 선택 해제되면 attachment 제거
    //         attachments.entity(for: "selectedId")?.removeFromParent()
    //     }
    // }

    /// 드래그 중 처리
    private func handleDragChanged(_ value: EntityTargetValue<DragGesture.Value>) {
        value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
    }
    
    /// 드래그 종료 처리
    private func handleDragEnded(_ value: EntityTargetValue<DragGesture.Value>) {
        guard let uuid = UUID(uuidString: value.entity.name) else {
            return
        }
        
        sceneModel.updateObjectPosition(id: uuid, position: value.entity.position)
        print("📍 위치 업데이트: \(uuid) → \(value.entity.position)")
    }
    
    // MARK: - Attachment 액선
    
    /// SceneObject 크롭
    // private func cropObject() {
    //     print("✂️ 크롭 기능 - 향후 구현 예정")
    //     // TODO: 크롭 기능 구현
    // }
    
    // /// SceneObject 삭제
    // private func deleteObject() {
    //     sceneModel.removeSceneObject(id: selectedEntity.id)
    //     selectedEntity = nil
    //     print("🗑️ 삭제 완료: \(selectedEntity.id)")
    // }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(SceneModel())
}
