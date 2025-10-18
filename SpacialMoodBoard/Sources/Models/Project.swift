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
  var projectDirectory: URL?
  let createdAt: Date
  var updatedAt: Date
  var volumeScene: VolumeScene?

  init(
    id: UUID = UUID(),
    title: String,
    thumbnailImage: String? = nil,
    projectDirectory: URL? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    volumeScene: VolumeScene? = nil
  ) {
    self.id = id
    self.title = title
    self.thumbnailImage = thumbnailImage
    self.projectDirectory = projectDirectory
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.volumeScene = volumeScene
  }
}

