//
//  FileImportStrategy.swift
//  Glayer
//
//  Created by jeongminji on 11/2/25.
//

import UIKit

final class FileUrlsStrategy: ImportStrategyInterface {
    
    // MARK: - Methods
    
    /// 파일 URL 소스로부터 이미지 또는 사운드 데이터를 수집
    /// - Parameter request: 임포트 요청(`ImportRequest`)
    /// - Returns: 이미지인 경우 `.uiImages([UIImage])`, 사운드인 경우 `.fileUrls([URL])`
    func collect(_ request: ImportRequest) async throws -> ImportPayload {
        guard case let .fileUrls(urls) = request.source, !urls.isEmpty else {
            throw ImportError.nothingToImport
        }

        switch request.kind {
        case .image:
            var images: [UIImage] = []
            images.reserveCapacity(urls.count)
            for url in urls.prefix(request.limit) {
                let needs = url.startAccessingSecurityScopedResource()
                defer { if needs { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) {
                    images.append(img)
                }
            }
            guard !images.isEmpty else { throw ImportError.conversionFailed }
            return .uiImages(images)

        case .sound:
            return .fileUrls(Array(urls.prefix(request.limit)))
        }
    }
}
