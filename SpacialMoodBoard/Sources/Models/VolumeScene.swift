//
//  Scene.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import Foundation

struct VolumeScene: Identifiable, Codable, Equatable {
  let id: UUID
  var groundSizeX: Int
  var groundSizeY: Int
  var groundSizeZ: Int
  var roomType: RoomType
  var viewMode: Bool
  
  init(
    id: UUID = UUID(),
    groundSizeX: Int,
    groundSizeY: Int,
    groundSizeZ: Int,
    roomType: RoomType,
    viewMode: Bool = false,
  ) {
    self.id = id
    self.groundSizeX = groundSizeX
    self.groundSizeY = groundSizeY
    self.groundSizeZ = groundSizeZ
    self.roomType = roomType
    self.viewMode = viewMode
  }
  
  init(
    id: UUID = UUID(),
    preset: GroundSizePreset,
    roomType: RoomType,
    viewMode: Bool = false
  ) {
    let dimensions = preset.dimensions
    self.init(
      id: id,
      groundSizeX: dimensions.x,
      groundSizeY: dimensions.y,
      groundSizeZ: dimensions.z,
      roomType: roomType,
      viewMode: viewMode,
    )
  }
}
