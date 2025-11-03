import Foundation
import RealityKit

// MARK: - Floor Features

extension SceneViewModel {

    // MARK: - Floor URL

    /// Floor 이미지 URL (AssetRepository에서 Asset ID로 조회)
    var floorImageURL: URL? {
        guard let assetId = spacialEnvironment.floorAssetId else { return nil }
        return assetRepository.asset(withId: assetId)?.url
    }

    // MARK: - Floor Material

    /// Floor entity의 material만 업데이트 (entity 재생성 없이)
    /// - Parameters:
    ///   - floor: 업데이트할 floor entity
    ///   - imageURL: 새로운 floor 이미지 URL (nil이면 기본 회색 material)
    func updateFloorMaterial(on floor: ModelEntity, with imageURL: URL?) {
        do {
            let material: PhysicallyBasedMaterial
            let opacity: Float

            if let imageURL = imageURL {
                // 이미지가 있을 때: opacity 1.0 (완전 불투명)
                let texture = try TextureResource.load(contentsOf: imageURL)
                material = FloorEntity.createMaterial(texture: texture)
                opacity = 1.0
            } else {
                // 기본 상태: opacity 0.3 (반투명)
                material = FloorEntity.createMaterial()
                opacity = 0.3
            }

            floor.model?.materials = [material]
            floor.components[OpacityComponent.self] = .init(opacity: opacity)
        } catch {
            print("⚠️ Floor material 업데이트 실패: \(error.localizedDescription)")
        }
        appliedFloorImageURL = imageURL
    }

    func applyFloorImage(from asset: Asset) {
        guard asset.type == .image else {
            return
        }

        // SpacialEnvironment에 Asset ID 저장 (SceneObject와 동일한 방식)
        var updatedEnvironment = spacialEnvironment
        updatedEnvironment.floorAssetId = asset.id
        spacialEnvironment = updatedEnvironment

        // 변경사항 저장
        saveScene()
    }

    /// Floor 이미지 제거
    func removeFloorImage() {
        // SpacialEnvironment에서 Asset ID 제거
        var updatedEnvironment = spacialEnvironment
        updatedEnvironment.floorAssetId = nil
        spacialEnvironment = updatedEnvironment

        // 변경사항 저장
        saveScene()
    }

    // MARK: - Floor Geometry

    func rotateBy90Degrees() {
        rotationAngle += .pi / 2

        guard let FloorEntity = getFloorEntity() else { return }

        applyRotation(to: FloorEntity, angle: rotationAngle, animated: true)
    }

    func resetRotation() {
        rotationAngle = 0

        guard let FloorEntity = getFloorEntity() else { return }

        applyRotation(to: FloorEntity, angle: rotationAngle, animated: false)
    }

    func alignFloorToWindowBottom(
        _ entity: Entity,
        windowHeight: Float = 1,
        padding: Float = 0
    ) {
        let bounds = entity.visualBounds(relativeTo: entity)
        let contentMinY = bounds.min.y
        let windowBottomY = -windowHeight / 2.0
        let targetContentMinY = windowBottomY + padding
        let offsetY = targetContentMinY - contentMinY

        var transform = entity.transform
        transform.translation.y = offsetY
        entity.transform = transform
    }

    // MARK: - Private Helpers

    private func applyRotation(to entity: Entity, angle: Float, animated: Bool) {
        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])

        if animated {
            var transform = entity.transform
            transform.rotation = rotation
            entity.move(to: transform, relativeTo: entity.parent, duration: 0.3)
        } else {
            entity.transform.rotation = rotation
        }
    }
}
