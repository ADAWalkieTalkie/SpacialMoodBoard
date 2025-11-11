//
//  AssetUsageIndex.swift
//  Glayer
//
//  Created by jeongminji on 10/24/25.
//

import Foundation

@MainActor
protocol AssetUsageIndexProtocol: AnyObject {
    func register(objectId: UUID, assetId: String)
    func unregister(objectId: UUID, assetId: String)
    func usages(of assetId: String) -> Set<UUID>
}

@MainActor
final class AssetUsageIndex: AssetUsageIndexProtocol {
    private var map: [String: Set<UUID>] = [:]
    
    func register(objectId: UUID, assetId: String) {
        map[assetId, default: []].insert(objectId)
    }
    func unregister(objectId: UUID, assetId: String) {
        guard var set = map[assetId] else { return }
        set.remove(objectId)
        map[assetId] = set.isEmpty ? nil : set
    }
    func usages(of assetId: String) -> Set<UUID> {
        map[assetId] ?? []
    }
}
