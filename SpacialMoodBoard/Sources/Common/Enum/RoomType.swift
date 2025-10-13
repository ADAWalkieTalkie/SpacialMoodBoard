//
//  RoomType.swift
//  SpacialMoodBoard
//
//  Created by PenguinLand on 10/13/25.
//

enum RoomType: String, Codable, CaseIterable {
  case indoor = "실내"
  case outdoor = "야외"
  
  var displayName: String {
    return self.rawValue
  }
  
  // 추후 이미지URL로 수정
  var iconName: String {
    switch self {
    case .indoor: return "house.fill"
    case .outdoor: return "cloud.fill"
    }
  }
}
