//
//  ProjectList+MockData.swift
//  Glayer
//
//  Created by PenguinLand on 10/9/25.
//

import Foundation

extension Project {
    static let mockData: [Project] = [
        Project(
            id: UUID(),
            title: "기생충(기우의 방)",
            thumbnailImage: nil,
            projectDirectory: FilePathProvider.projectDirectory(
                projectName: "기생충(기우의 방)"
            ),
            createdAt: Calendar.current.date(
                byAdding: .day,
                value: -7,
                to: Date()
            ) ?? Date(),
            updatedAt: Calendar.current.date(
                byAdding: .hour,
                value: -2,
                to: Date()
            ) ?? Date()
        ),

        Project(
            id: UUID(),
            title: "헤어질 결심(결말)",
            thumbnailImage: nil,
            projectDirectory: FilePathProvider.projectDirectory(
                projectName: "헤어질 결심(결말)"
            ),
            createdAt: Calendar.current.date(
                byAdding: .day,
                value: -14,
                to: Date()
            ) ?? Date(),
            updatedAt: Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: Date()
            ) ?? Date()
        ),

        Project(
            id: UUID(),
            title: "어쩔 수가 없다(이병헌 방)",
            thumbnailImage: nil,
            projectDirectory: FilePathProvider.projectDirectory(
                projectName: "어쩔 수가 없다(이병헌 방)"
            ),
            createdAt: Calendar.current.date(
                byAdding: .day,
                value: -21,
                to: Date()
            ) ?? Date(),
            updatedAt: Calendar.current.date(
                byAdding: .hour,
                value: -5,
                to: Date()
            ) ?? Date()
        ),

        Project(
            id: UUID(),
            title: "니모의 하루",
            thumbnailImage: nil,
            projectDirectory: FilePathProvider.projectDirectory(
                projectName: "니모의 하루"
            ),
            createdAt: Calendar.current.date(
                byAdding: .month,
                value: -1,
                to: Date()
            ) ?? Date(),
            updatedAt: Calendar.current.date(
                byAdding: .day,
                value: -3,
                to: Date()
            ) ?? Date()
        )
    ]
}
