//
//  ClipboardStrategy.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/2/25.
//

import UIKit
import UniformTypeIdentifiers

final class ClipboardStrategy: ImportStrategyInterface {
    
    // MARK: - Methods
    
    /// 클립보드 내용을 가져오기 요청에 맞춰 변환
    /// - Parameter request: 가져오기 요청 정보(소스, 종류 등)를 포함한 구조체
    /// - Returns: 이미지인 경우 `ImportPayload.uiImages`, 사운드인 경우 `ImportPayload.fileUrls`
    /// - Throws: 변환 가능한 데이터가 없거나 지원하지 않는 경우 `ImportError.nothingToImport`를 던짐
    func collect(_ request: ImportRequest) async throws -> ImportPayload {
        switch request.kind {
        case .image:
            if let img = UIPasteboard.general.image { return .uiImages([img]) }
            if let data = UIPasteboard.general.data(forPasteboardType: UTType.image.identifier),
               let img = UIImage(data: data) { return .uiImages([img]) }
            if let url = UIPasteboard.general.url,
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) { return .uiImages([img]) }
            if let s = UIPasteboard.general.string, let url = URL(string: s),
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) { return .uiImages([img]) }
            throw ImportError.nothingToImport

        case .sound:
            if let url = UIPasteboard.general.url { return .fileUrls([url]) }
            throw ImportError.nothingToImport
        }
    }
}
