//
//  AssetRepositoryInterface.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/24/25.
//

import SwiftUI
import UIKit

/// 이미지/사운드 **에셋을 단일 인터페이스로 관리**하는 파사드
/// - DI(의존성 역전)로 이미지/사운드 서비스가 주입됨
/// - `SceneObject ↔ Asset` **참조 테이블**을 내부에서 관리
/// - 에셋 삭제 시, 해당 에셋을 참조하던 `SceneObject`들의 ID를 반환하여
///   상위 계층(UseCase/Coordinator)이 엔티티 정리를 일괄 수행할 수 있게 함
/// - Thread-safety: UI와 동기화를 위해 전체가 `@MainActor`
@MainActor
protocol AssetRepositoryInterface: AnyObject {

    // MARK: 상태/동기화

    var project: String { get }
    var assets: [Asset] { get }

    /// 디스크/서비스로부터 에셋 목록을 재로딩하여 `assets`를 갱신합니다.
    /// - Note: 파형 등 부가 메타는 비동기로 채워질 수 있습니다.
    func reload() async

    // MARK: 조회

    /// ID로 단일 에셋 조회
    /// - Parameter id: 에셋 식별자
    /// - Returns: 일치하는 `Asset` 또는 `nil`
    func asset(withId id: String) -> Asset?

    /// 타입별 에셋 목록 조회
    /// - Parameter type: `.image` 또는 `.sound`
    /// - Returns: 해당 타입의 `Asset` 배열
    func assets(of type: AssetType) -> [Asset]

    // MARK: 생성/추가

    #if canImport(UIKit)
    /// `UIImage`를 저장하고 에셋을 생성
    /// - Parameters:
    ///   - image: 저장할 이미지
    ///   - filename: 저장 파일명(중복 시 내부에서 고유화)
    /// - Returns: 생성된 `Asset`
    /// - Throws: 파일 쓰기/메타 생성 실패 등
    func addImage(_ image: UIImage, filename: String) async throws -> Asset
    #endif

    /// 이미지 데이터로 에셋을 생성
    /// - Parameters:
    ///   - data: 이미지 바이너리 데이터
    ///   - filename: 저장 파일명(중복 시 내부에서 고유화)
    /// - Returns: 생성된 `Asset`
    /// - Throws: 파일 쓰기/메타 생성 실패 등
    func addImageData(_ data: Data, filename: String) async throws -> Asset

    /// 사운드 데이터로 에셋을 생성
    /// - Parameters:
    ///   - data: 오디오 바이너리 데이터
    ///   - filename: 저장 파일명(중복 시 내부에서 고유화)
    /// - Returns: 생성된 `Asset`(파형 등 메타는 비동기 보강될 수 있음)
    /// - Throws: 파일 쓰기/메타 생성 실패 등
    func addSoundData(_ data: Data, filename: String) async throws -> Asset

    // MARK: 이름 변경/복제/삭제

    /// 에셋의 파일명을 변경하고, 변경 결과의 **갱신된 `Asset`**을 반환합니다.
    /// - Important: ID 정책이 `contentHash@filename` 등 파일명 포함일 경우,
    ///   이름 변경과 함께 **에셋 ID가 변경될 수 있습니다.**
    /// - Parameters:
    ///   - id: 기존 에셋 ID.
    ///   - newBaseName: 변경할 새 기본 파일명(확장자는 서비스에서 유지/결정).
    /// - Returns: 변경 반영된 `Asset`(필요 시 새 ID 포함).
    /// - Throws: 파일 이름 변경 실패, 중복 파일명 충돌 등.
    @discardableResult
    func renameAsset(id: String, to newBaseName: String) throws -> Asset

    /// 에셋을 복제하여 새 파일로 저장하고, 복제된 `Asset`을 반환합니다.
    /// - Parameters:
    ///   - id: 원본 에셋 ID.
    ///   - newBaseName: 새 기본 파일명(미지정 시 내부 기본값 사용, 예: "Copy").
    /// - Returns: 복제된 `Asset`.
    /// - Throws: 파일 복사/메타 생성 실패 등.
    func duplicateAsset(id: String, as newBaseName: String?) async throws -> Asset

    /// 에셋을 삭제하고, 해당 에셋을 참조하던 `SceneObject` ID들을 반환합니다
    /// - Parameter id: 삭제할 에셋 ID
    /// - Throws: 파일 삭제 실패 등
    func deleteAsset(id: String) throws

    // MARK: 옵저버

    /// 에셋 목록/메타 변경 시 호출될 콜백을 등록
    /// - Parameter f: 변경 콜백(메인 스레드에서 호출)
    /// - Returns: 핸들 제거에 사용할 토큰 ID
    @discardableResult
    func addChangeHandler(_ f: @escaping () -> Void) -> UUID

    /// 등록된 변경 콜백을 제거
    /// - Parameter id: `addChangeHandler`가 반환한 토큰 ID
    func removeChangeHandler(_ id: UUID)
}
