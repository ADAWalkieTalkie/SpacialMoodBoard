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
        RealityView { content in
            
            let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
            anchor.name = "RootSceneAnchor"
            content.add(anchor)

            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                anchor.addChild(immersiveContentEntity)
            }
        } update: { content in

            guard let anchor = content.entities.first(where: { $0.name == "RootSceneAnchor" }) as? AnchorEntity else {
                print("❌ AnchorEntity를 찾을 수 없습니다.")
                return
            }
            // SceneObject들을 Entity로 변환하여 추가
            updateEntities(anchor: anchor)

            // Attachment를 선택된 Entity에 연결
            updateAttachmentComponent(selectedEntity: selectedEntity)

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
    private func updateEntities(anchor: AnchorEntity) {
        let currentObjectIds = Set(sceneModel.sceneObjects.map { $0.id })
        let existingEntityIds = Set(entityMap.keys)
        
        // 1. 삭제된 객체 제거
        for removedId in existingEntityIds.subtracting(currentObjectIds) {
            if let entity = entityMap[removedId] {
                entity.removeFromParent()
                Task { @MainActor in
                    entityMap.removeValue(forKey: removedId)
                }
            }
        }
        
        // 2. 새로운 객체 추가 또는 업데이트
        for sceneObject in sceneModel.sceneObjects {
            guard let asset = assets.first(where: { $0.id == sceneObject.assetId }) else {
                continue
            }
            
            if let existingEntity = entityMap[sceneObject.id] {
                existingEntity.position = sceneObject.position
            } else {
                if let entity = ImageEntity.create(from: sceneObject, with: asset, viewMode: sceneModel.userSpatialState.viewMode) {
                    anchor.addChild(entity)  // ✅ anchor에 추가
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
    
    // MARK: - DrageGuesture 관련
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

    // MARK: - Attachment 관리
    
    /// Attachment를 선택된 Entity에 연결
    private func updateAttachmentComponent(selectedEntity entity: Entity?) {

        for entity in entityMap.values {
            entity.children
                .filter { $0.name == "objectAttachment" }  // attachment만 필터링
                .forEach { $0.removeFromParent() }          // 제거
        }
        guard let entity = entity,
            let objectId = UUID(uuidString: entity.name) else { return }

        let objectAttachment = Entity()
        objectAttachment.name = "objectAttachment"
        let attachment = ViewAttachmentComponent(
            rootView: ImageAttachment(
                objectId: objectId,
                onDuplicate: {
                    duplicateObject(selectedEntity: selectedEntity)
                },
                onCrop: {
                    cropObject()
                },
                onDelete: {
                    deleteObject(selectedEntity: selectedEntity)
                }
            )
        )
        objectAttachment.components.set(attachment)
        entity.addChild(objectAttachment)

        let objectBounds = entity.visualBounds(relativeTo: entity)
        let attachmentBounds = objectAttachment.visualBounds(relativeTo: objectAttachment)

        let yOffset = objectBounds.max.y + attachmentBounds.max.y / 2 + 0.05
        let transform = Transform(translation: SIMD3<Float>(0, yOffset, 0))
        objectAttachment.transform = transform
    }
    
    // MARK: - Attachment 액선

    private func duplicateObject(selectedEntity: ModelEntity?) {
        guard let selectedEntity = selectedEntity,
            let objectId = UUID(uuidString: selectedEntity.name),
            let originalObject = sceneModel.sceneObjects.first(where: { $0.id == objectId })
        else {
            print("❌ 복제할 객체를 찾을 수 없습니다")
            return
        }
        
        // ✅ 원본 객체의 속성을 가져와서 새 객체 생성
        guard case .image(let imageAttrs) = originalObject.attributes else {
            print("❌ 이미지 타입만 복제 가능합니다")
            return
        }
        
        // ✅ 새로운 위치 계산 (기존 위치 + offset)
        let newPosition = originalObject.position + SIMD3<Float>(-0.1, 0.1, 0)
        
        // ✅ 새로운 SceneObject 생성 (새 UUID 자동 생성)
        let duplicatedObject = SceneObject.createImage(
            assetId: originalObject.assetId,
            position: newPosition,
            isEditable: originalObject.isEditable,
            scale: imageAttrs.scale,
            rotation: imageAttrs.rotation,
            crop: imageAttrs.crop,
            billboardable: imageAttrs.billboardable
        )
        
        // ✅ SceneModel에 추가 → updateEntities가 자동으로 Entity 생성
        sceneModel.sceneObjects.append(duplicatedObject)

        self.selectedEntity = nil
        
        print("✅ 복사 완료: \(originalObject.id) → \(duplicatedObject.id)")
        print("📍 원본 위치: \(originalObject.position)")
        print("📍 복사본 위치: \(duplicatedObject.position)")
    }

    private func cropObject() {
        print("✂️ 크롭 기능 - 향후 구현 예정")
        // TODO: 크롭 기능 구현
    }
    
    /// SceneObject 삭제
    private func deleteObject(selectedEntity: ModelEntity?) {
        guard let selectedEntity = selectedEntity else { return }
        sceneModel.removeSceneObject(id: UUID(uuidString: selectedEntity.name)!)
        self.selectedEntity = nil
        print("🗑️ 삭제 완료: \(selectedEntity.name)")
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(SceneModel())
}
