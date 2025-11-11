//
//  Project.swift
//  Glayer
//
//  Created by PenguinLand on 10/4/25.
//

import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    var thumbnailImage: String?
    var projectDirectory: URL?
    private(set) var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        thumbnailImage: String? = nil,
        projectDirectory: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.thumbnailImage = thumbnailImage
        self.projectDirectory = projectDirectory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Codable required initializer must be in class body
    // Mark nonisolated to avoid accidentally isolating the type if a surrounding @MainActor exists.
    nonisolated required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.thumbnailImage = try container.decodeIfPresent(String.self, forKey: .thumbnailImage)
        self.projectDirectory = try container.decodeIfPresent(URL.self, forKey: .projectDirectory)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

// MARK: - Codable Support for JSON Storage
extension Project: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailImage
        case projectDirectory
        case createdAt
        case updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(thumbnailImage, forKey: .thumbnailImage)
        try container.encodeIfPresent(projectDirectory, forKey: .projectDirectory)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
