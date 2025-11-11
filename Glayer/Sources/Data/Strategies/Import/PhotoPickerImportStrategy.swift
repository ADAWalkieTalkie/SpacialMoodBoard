//
//  PhotoPickerImportStrategy.swift
//  Glayer
//
//  Created by jeongminji on 11/2/25.
//

import SwiftUI
import PhotosUI

final class PhotoPickerStrategy: ImportStrategyInterface {
    
    // MARK: - Methods
    
    /// PhotosPicker에서 전달된 선택 항목들을 요청된 타입에 맞는 페이로드로 변환
    /// - Parameter request: 사진 피커 소스(`.photosPicker(items, limit)`)와 가져오기 종류(kind)를 포함한 요청
    /// - Returns: 이미지의 경우 `ImportPayload.uiImages`.
    /// - Throws: 변환 가능한 이미지가 없을 때 `ImportError.conversionFailed`,
    ///           지원하지 않는 소스/종류일 때 `ImportError.nothingToImport`를 던질 수 있음
    func collect(_ request: ImportRequest) async throws -> ImportPayload {
        guard case let .photosPicker(items, limit) = request.source else { throw ImportError.nothingToImport }
        let selected = Array(items.prefix(limit))
        
        switch request.kind {
        case .image:
            var images: [UIImage] = []
            images.reserveCapacity(selected.count)
            for item in selected {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    images.append(img); continue
                }
                
                if let url = try? await item.loadTransferable(type: URL.self),
                   let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) {
                    images.append(img); continue
                }
            }
            guard !images.isEmpty else { throw ImportError.conversionFailed }
            return .uiImages(images)
            
        case .sound:
            throw ImportError.nothingToImport
        }
    }
}
