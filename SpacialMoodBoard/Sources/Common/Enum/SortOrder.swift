//
//  SortOrder.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

enum SortOrder: Int, CaseIterable, Identifiable {
    case recent, nameAZ
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .recent: return "최신순"
        case .nameAZ:   return "이름순"
        }
    }
}
