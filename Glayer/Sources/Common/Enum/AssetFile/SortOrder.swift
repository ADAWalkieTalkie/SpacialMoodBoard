//
//  SortOrder.swift
//  Glayer
//
//  Created by jeongminji on 10/21/25.
//

import Foundation

enum SortOrder: Hashable, Identifiable, Equatable {
    case sort(Sort)
    case origin(Origin)

    enum Sort: CaseIterable { case recent, nameAZ }
    enum Origin: CaseIterable { case basicOnly, userOnly }

    var id: String { title }
    var title: String {
        switch self {
        case .sort(.recent):      return String(localized: "sort.mostRecent")
        case .sort(.nameAZ):      return String(localized: "sort.byName")
        case .origin(.basicOnly): return String(localized: "sort.basicAssets")
        case .origin(.userOnly):  return String(localized: "sort.userAdded")
        }
    }
}
