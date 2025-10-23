//
//  AssetRepositoryInterface.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/24/25.
//

import SwiftUI
import UIKit

// MARK: - RepositoryInterface

/// 이미지/사운드 에셋을 단일 인터페이스로 관리하는 파사드
/// - 서비스는 주입(의존성 역전)
/// - SceneObject ↔ Asset 참조 테이블을 내부에서 관리
/// - 삭제 시, 참조 중인 오브젝트 ID들을 반환하여 상층에서 일괄 제거
@MainActor
protocol AssetRepositoryInterface: AnyObject {
    var project: String { get }
    var assets: [Asset] { get }
    func reload() async
    
    // 조회
    func asset(withId id: String) -> Asset?
    func assets(of type: AssetType) -> [Asset]
    
    // 생성/추가
#if canImport(UIKit)
    func addImage(_ image: UIImage, filename: String) async throws -> Asset
#endif
    func addImageData(_ data: Data, filename: String) async throws -> Asset
    func addSoundData(_ data: Data, filename: String) async throws -> Asset
    
    // 이름 변경/복제/삭제
    func renameAsset(id: String, to newBaseName: String) throws
    func duplicateAsset(id: String, as newBaseName: String?) async throws -> Asset
    /// 에셋 삭제. 이 에셋을 참조하던 SceneObject들의 id를 반환
    func deleteAsset(id: String) throws -> [UUID]
    
    // 참조 테이블
    func registerReference(objectId: UUID, assetId: String)
    func unregisterReference(objectId: UUID, assetId: String)
    func dependents(of assetId: String) -> [UUID]
    
    // 옵저버
    @discardableResult
    func addChangeHandler(_ f: @escaping () -> Void) -> UUID
    func removeChangeHandler(_ id: UUID)
}
