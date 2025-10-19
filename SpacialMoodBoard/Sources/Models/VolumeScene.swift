//
//  Scene.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/11/25.
//

import Foundation

struct VolumeScene: Identifiable, Codable, Equatable {
  let id: UUID
  var roomType: RoomType
  let groundSize: GroundSize
  var viewMode: Bool
  
  init(
    id: UUID = UUID(),
    roomType: RoomType,
    groundSize: GroundSize,
    viewMode: Bool = false,
  ) {
    self.id = id
    self.roomType = roomType
    self.groundSize = groundSize
    self.viewMode = viewMode
  }
}
