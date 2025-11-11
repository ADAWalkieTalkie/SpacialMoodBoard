//
//  SortOrder.swift
//  Glayer
//
//  Created by jeongminji on 10/21/25.
//

enum SortOrder: Hashable, Identifiable, Equatable {
    case sort(Sort)
    case origin(Origin)

    enum Sort: CaseIterable { case recent, nameAZ }
    enum Origin: CaseIterable { case basicOnly, userOnly }

    var id: String { title }
    var title: String {
        switch self {
        case .sort(.recent):      return "최신순"
        case .sort(.nameAZ):      return "이름순"
        case .origin(.basicOnly): return "기본 에셋"
        case .origin(.userOnly):  return "직접 추가"
        }
    }
}
