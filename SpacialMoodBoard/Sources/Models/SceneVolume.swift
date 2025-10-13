//
//  Scene.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import Foundation

enum RoomType: String, Codable, CaseIterable {
  case indoor = "실내"
  case outdoor = "야외"
  
  var displayName: String {
    return self.rawValue
  }
  
  // 추후 이미지로 수정
  var iconName: String {
    switch self {
    case .indoor: return "house.fill"
    case .outdoor: return "cloud.fill"
    }
  }
}

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
  
  // 추후 이미지로 수정
  var iconName: String {
    switch self {
    case .small: return "cube.fill"
    case .medium: return "building.fill"
    case .large: return "building.2.fill"
    }
  }
  
}

struct SceneVolume {
  let id: UUID
  let projectID: UUID
  var groundSizeX: Int
  var groundSizeY: Int
  var groundSizeZ: Int
  var roomType: RoomType
  var viewMode: Bool
  
  init(
    id: UUID = UUID(),
    projectID: UUID,
    groundSizeX: Int,
    groundSizeY: Int,
    groundSizeZ: Int,
    roomType: RoomType,
    viewMode: Bool = false,
  ) {
    self.id = id
    self.projectID = projectID
    self.groundSizeX = groundSizeX
    self.groundSizeY = groundSizeY
    self.groundSizeZ = groundSizeZ
    self.roomType = roomType
    self.viewMode = viewMode
  }
  
  init(
    id: UUID = UUID(),
    projectID: UUID,
    preset: GroundSizePreset,
    roomType: RoomType,
    viewMode: Bool = false
  ) {
    let dimensions = preset.dimensions
    self.init(
      id: id,
      projectID: projectID,
      groundSizeX: dimensions.x,
      groundSizeY: dimensions.y,
      groundSizeZ: dimensions.z,
      roomType: roomType,
      viewMode: viewMode,
    )
  }
  
}
