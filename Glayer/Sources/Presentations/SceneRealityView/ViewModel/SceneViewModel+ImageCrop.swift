//
//  SceneViewModel+ImageCrop.swift
//  Glayer
//
//  Created by jeongminji on 11/13/25.
//

import UIKit
import RealityKit
import SwiftUI

extension SceneViewModel {
    /// EditBar에서 '크롭' 버튼을 눌렀을 때 호출되어 선택된 이미지 엔티티 위에 크롭 UI(CropAttachment)를 띄움
    /// 내부 동작:
    /// 1. 현재 `SceneObject`에서 이미지 에셋과 기존 크롭 정보(UVRect)를 조회
    /// 2. 해당 이미지를 이용해 `CropAttachment` SwiftUI 뷰를 생성하고,
    ///    ViewAttachmentComponent로 감싼 뒤 `cropAttachment` 엔티티에 부착
    /// 3. `EntityAttachmentSizeDeterminator.scaleAttachmentToBound`를 통해
    ///    부모 이미지 엔티티의 boundBox 크기에 맞도록 어태치먼트 스케일을 보정하고,
    ///    이 스케일 값을 다시 `CropAttachment`에 주입해 테두리 두께 등을 맞춤
    /// 4. 사용자가 크롭을 완료하면 `onDone` 콜백을 통해 새 UVRect를 전달받고,
    ///    `updateObjectCrop`을 호출해 실제 Scene/Entity에 반영
    ///
    /// - Parameters:
    ///   - entity: 크롭 UI를 겹쳐 표시할 대상 이미지 `ModelEntity`
    ///   - objectId: 크롭 상태를 갱신할 `SceneObject`의 식별자(UUID)
    func startImageCrop(for entity: ModelEntity, objectId: UUID) {
        attachmentTimer?.cancel()
        
        guard
            let obj = sceneObjects.first(where: { $0.id == objectId }),
            case .image(let attrs) = obj.attributes,
            let asset = assetRepository.asset(withId: obj.assetId),
            let uiImage = UIImage(contentsOfFile: asset.url.path) ?? UIImage(named: asset.filename)
        else { return }
        
        let initialUV: UVRect = attrs.crop.clamped()
        
        let cropAttachment = Entity()
        cropAttachment.name = "cropAttachment"
        
        let onDone: (UVRect) -> Void = { [weak self] newUV in
            guard let self else { return }
            self.updateObjectCrop(id: objectId, uv: newUV)
        }
        
        let baseView = CropAttachment(
            image: uiImage,
            initialUV: initialUV,
            scaleX: 1.0,
            scaleY: 1.0,
            onDone: onDone
        )
        cropAttachment.components.set(ViewAttachmentComponent(rootView: baseView))
        entity.addChild(cropAttachment)
        
        let (scaleX, scaleY) = EntityAttachmentSizeDeterminator.scaleAttachmentToBound(cropAttachment, on: entity)
        
        let scaledView = CropAttachment(
            image: uiImage,
            initialUV: initialUV,
            scaleX: scaleX,
            scaleY: scaleY,
            onDone: onDone
        )
        EntityBoundBoxApplier.removeBoundBox(from: entity)
        cropAttachment.components.set(ViewAttachmentComponent(rootView: scaledView))
    }
    
    /// 선택된 이미지 객체의 크롭 정보(UVRect)를 갱신하고, 장면(Scene) 상태 및 실제 RealityKit 엔티티 양쪽 모두에 반영
    /// - Discussion:
    ///   1. `sceneObjectRepository`를 통해 상태 계층(모델 데이터)에서
    ///      해당 오브젝트의 `crop` 값을 업데이트하고 자동 저장을 예약
    ///   2. 이후 기존 RealityKit 엔티티를 제거 + `entityRepository`에서 캐시 제거
    ///   3. 같은 `SceneObject`를 기반으로 `createEntity`를 다시 호출해 새 엔티티를 생성
    /// - Parameters:
    ///   - id: 갱신할 `SceneObject`의 고유 식별자(UUID)
    ///   - uv: 새로 적용할 크롭 영역을 나타내는 `UVRect`
    ///         (0~1 비율 기준, RealityKit의 y축 방향은 내부에서 자동 보정)
    func updateObjectCrop(id: UUID, uv: UVRect) {
        guard
            var scene = appStateManager.selectedScene,
            let root = rootEntity
        else { return }
        
        let u = uv.clamped()
        
        var updatedObject: SceneObject?
        
        sceneObjectRepository.updateObject(id: id, in: &scene) { obj in
            obj.setCrop(u)
            updatedObject = obj
        }
        
        appStateManager.updateSelectedScene(scene)
        scheduleSceneAutosaveDebounced()
        
        guard
            let object = updatedObject,
            let asset = assetRepository.asset(withId: object.assetId)
        else { return }
        
        entityRepository.removeEntity(id: id)
        if let old = root.findEntity(named: id.uuidString) {
            old.removeFromParent()
        }
        
        _ = entityRepository.createEntity(
            from: object,
            asset: asset,
            rootEntity: root
        )
        
        selectedEntity = nil
    }
    
    
    /// 엔티티에 붙어있는 크롭 UI(CropAttachment)를 제거
    /// - Parameter entity: 크롭 UI가 부착되어 있는 대상 `ModelEntity`
    func removeCropAttachment(from entity: ModelEntity) {
        entity.findEntity(named: "cropAttachment")?.removeFromParent()
    }
}
