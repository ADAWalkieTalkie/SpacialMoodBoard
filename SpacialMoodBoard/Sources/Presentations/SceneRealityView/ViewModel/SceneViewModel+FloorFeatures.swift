import Foundation
import RealityKit

// MARK: - Floor Features

extension SceneViewModel {

    // MARK: - Floor Material

    /// Floor entity의 material만 업데이트 (entity 재생성 없이)
    /// - Parameters:
    ///   - floor: 업데이트할 floor entity
    ///   - imageURL: 새로운 floor 이미지 URL (nil이면 기본 회색 material)
    func updateFloorMaterial(on floor: ModelEntity, with imageURL: URL?) {
        do {
            let material: PhysicallyBasedMaterial
            if let imageURL = imageURL {
                let texture = try TextureResource.load(contentsOf: imageURL)
                material = FloorEntity.createMaterial(texture: texture)
            } else {
                // nil이면 기본 회색 material 적용
                material = FloorEntity.createMaterial()
            }
            floor.model?.materials = [material]
        } catch {
            print("⚠️ Floor material 업데이트 실패: \(error.localizedDescription)")
        }
        appliedFloorImageURL = imageURL
    }

    func applyFloorImage(from asset: Asset) {
        guard asset.type == .image else {
            return
        }

        // Documents 디렉토리로부터의 상대 경로 계산
        let relativePath: String?
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentsPathWithSlash = documentsURL.path + "/"
            if asset.url.path.hasPrefix(documentsPathWithSlash) {
                relativePath = String(asset.url.path.dropFirst(documentsPathWithSlash.count))
            } else {
                print("⚠️ Asset이 Documents 디렉토리 내에 없음: \(asset.url.path)")
                relativePath = nil
            }
        } else {
            print("⚠️ Documents 디렉토리를 찾을 수 없음")
            relativePath = nil
        }

        // SpacialEnvironment에 floor material URL과 상대 경로 저장
        var updatedEnvironment = spacialEnvironment
        updatedEnvironment.floorMaterialImageURL = asset.url
        updatedEnvironment.floorImageRelativePath = relativePath
        spacialEnvironment = updatedEnvironment

        // 선택 모드 해제
        isSelectingFloorImage = false

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
