//
//  ImageMaterialApplier.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/21/25.
//

import RealityKit
import UIKit

// MARK: - Material Application Error

enum MaterialApplicationError: LocalizedError {
  case invalidImageData
  case invalidCGImage
  case textureGenerationFailed
  case notModelEntity
  
  var errorDescription: String? {
    switch self {
    case .invalidImageData:
      return "이미지 데이터를 UIImage로 변환할 수 없습니다"
    case .invalidCGImage:
      return "UIImage를 CGImage로 변환할 수 없습니다"
    case .textureGenerationFailed:
      return "TextureResource 생성에 실패했습니다"
    case .notModelEntity:
      return "Entity가 ModelEntity가 아닙니다"
    }
  }
}

struct ImageMaterialApplier {
  /// Entity에 이미지를 material로 적용
  /// - Parameters:
  ///   - entity: Material을 적용할 Entity (ModelEntity여야 함)
  ///   - imageData: 적용할 이미지의 Data
  /// - Throws: MaterialApplicationError
  func applyImageMaterial(to entity: Entity, image imageData: Data) throws {
    // 1. ModelEntity 확인
    guard let modelEntity = entity as? ModelEntity else {
      throw MaterialApplicationError.notModelEntity
    }
    
    // 2. Data -> UIImage 변환
    guard let uiImage = UIImage(data: imageData) else {
      throw MaterialApplicationError.invalidImageData
    }
    
    // 3. UIImage -> CGImage 변환
    guard let cgImage = uiImage.cgImage else {
      throw MaterialApplicationError.invalidCGImage
    }
    
    // 4. TextureResource 생성
    let texture: TextureResource
    do {
      texture = try TextureResource(
        image: cgImage,
        options: .init(semantic: .color)
      )
    } catch {
      throw MaterialApplicationError.textureGenerationFailed
    }
    
    // 5. SimpleMaterial 생성
    var material = SimpleMaterial()
    material.color = .init(texture: .init(texture))
    material.metallic = .init(floatLiteral: 0.0)
    material.roughness = .init(floatLiteral: 0.5)
    
    // 6. Material 적용
    modelEntity.model?.materials = [material]
    
    print("Material 적용 완료: Entity[\(entity.name)]")
  }
  
  
}
