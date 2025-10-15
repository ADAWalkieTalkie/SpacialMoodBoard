//
//  Project.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/4/25.
//

import Foundation

struct Project: Identifiable, Codable, Equatable {
  let id: UUID
  var title: String
  var thumbnailImage: String?
  let createdAt: Date
  var updatedAt: Date
  var volumeEntity: VolumeScene

  init(
    id: UUID = UUID(),
    title: String,
    thumbnailImage: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    volumeEntity: VolumeScene
  ) {
    self.id = id
    self.title = title
    self.thumbnailImage = thumbnailImage
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.volumeEntity = volumeEntity
  }
}

