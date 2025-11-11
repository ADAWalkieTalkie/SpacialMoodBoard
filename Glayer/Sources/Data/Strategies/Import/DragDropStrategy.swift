//
//  DragDropStrategy.swift
//  Glayer
//
//  Created by jeongminji on 11/2/25.
//

import UIKit
import UniformTypeIdentifiers

final class DragDropStrategy: ImportStrategyInterface {
    
    // MARK: - Methods
    
    /// 드래그&드롭 소스에서 항목을 수집하고, **이미지** 페이로드로 변환
    /// - Parameter request: 드래그&드롭 `providers`와 제한 개수(limit)를 포함한 요청
    /// - Returns: 이미지 페이로드 `ImportPayload.uiImages.
    /// - Throws: 처리 가능한 이미지가 없거나, 지원하지 않는 타입(예: 사운드) 요청 시 에러
    func collect(_ request: ImportRequest) async throws -> ImportPayload {
        guard case let .dragDrop(providers) = request.source else { throw ImportError.nothingToImport }
        
        guard request.kind == .image else {
            throw ImportError.nothingToImport
        }
        
        let limited = Array(providers.prefix(request.limit))
        
        var images: [UIImage] = []
        images.reserveCapacity(limited.count)
        for p in limited {
            if p.canLoadObject(ofClass: UIImage.self) {
                if let img = await loadUIImage(provider: p) { images.append(img); continue }
            }
            
            let imageUTIs = [UTType.image.identifier, UTType.png.identifier, UTType.jpeg.identifier, UTType.heic.identifier]
            if let t = imageUTIs.first(where: { p.hasItemConformingToTypeIdentifier($0) }),
               let data = await loadData(provider: p, typeIdentifier: t),
               let img = UIImage(data: data) {
                images.append(img); continue
            }
            
            let urlUTIs = [UTType.fileURL.identifier, UTType.url.identifier]
            if let t = urlUTIs.first(where: { p.hasItemConformingToTypeIdentifier($0) }),
               let any = await loadItem(provider: p, typeIdentifier: t),
               let url = any as? URL,
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                images.append(img); continue
            }
        }
        guard !images.isEmpty else { throw ImportError.nothingToImport }
        return .uiImages(images)
    }
    
    // MARK: - Private Methods
    
    /// `NSItemProvider`로부터 `UIImage`를 비동기로 로드
    /// - Parameter provider: 드롭된 항목의 프로바이더
    /// - Returns: 로드 성공 시 `UIImage`, 실패 시 `nil`
    private func loadUIImage(provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { cont in
            provider.loadObject(ofClass: UIImage.self) { obj, _ in cont.resume(returning: obj as? UIImage) }
        }
    }
    
    /// `NSItemProvider`에서 지정한 UTI 타입의 바이너리 데이터를 비동기로 로드
    /// - Parameters:
    ///   - provider: 드롭된 항목의 프로바이더
    ///   - typeIdentifier: 예) `UTType.png.identifier`, `UTType.jpeg.identifier`
    /// - Returns: 로드된 `Data`(성공 시), 없거나 실패하면 `nil`
    private func loadData(provider: NSItemProvider, typeIdentifier: String) async -> Data? {
        await withCheckedContinuation { cont in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in cont.resume(returning: data) }
        }
    }
    
    /// `NSItemProvider`에서 지정한 UTI 타입의 아이템을 비동기로 가져옴 (파일/웹 URL 추출 등 폴백 경로에서 사용)
    /// - Parameters:
    ///   - provider: 드롭된 항목의 프로바이더
    ///   - typeIdentifier: 예) `UTType.fileURL.identifier`, `UTType.url.identifier`
    /// - Returns: 로드된 객체(`NSSecureCoding`)—대개 `URL`—없거나 실패하면 `nil`
    private func loadItem(provider: NSItemProvider, typeIdentifier: String) async -> NSSecureCoding? {
        await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in cont.resume(returning: item) }
        }
    }
}
