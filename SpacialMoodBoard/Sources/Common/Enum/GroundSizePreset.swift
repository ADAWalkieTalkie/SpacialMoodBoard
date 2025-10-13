//
//  GroundSizePreset.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/13/25.
//

enum GroundSizePreset: String, Codable, CaseIterable {
  case small = "Small"
  case medium = "Medium"
  case large = "Large"
  
  var dimensions: (x: Int, y: Int, z: Int) {
    switch self {
    case .small:
      return (x: 5, y: 3, z: 5)
    case .medium:
      return (x: 10, y: 4, z: 10)
    case .large:
      return (x: 15, y: 5, z: 15)
    }
  }
  
  // 추후 이미지URL로 수정
  var iconName: String {
    switch self {
    case .small: return "cube.fill"
    case .medium: return "building.fill"
    case .large: return "building.2.fill"
    }
  }
  
}
