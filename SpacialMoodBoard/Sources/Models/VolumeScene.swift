//
//  Scene.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import Foundation

struct VolumeScene: Identifiable, Codable, Equatable {
  let id: UUID
  let groundSize: GroundSize
  var roomType: RoomType
  var viewMode: Bool
  
  init(
    id: UUID = UUID(),
    groundSize: GroundSize,
    roomType: RoomType,
    viewMode: Bool = false,
  ) {
    self.id = id
    self.groundSize = groundSize
    self.roomType = roomType
    self.viewMode = viewMode
  }
}
