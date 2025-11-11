//
//  ImportStrategyInterface.swift
//  Glayer
//
//  Created by jeongminji on 11/2/25.
//

import PhotosUI
import SwiftUI

// TODO: - 사용하는게 ImportStrategyInterface를 위한 것 뿐이라 여기 두는게 좋을지 파일 빼는게 좋을지 논의 필요
struct ImportRequest {
    enum Source {
        case dragDrop(providers: [NSItemProvider])
        case photosPicker(items: [PhotosPickerItem], limit: Int)
        case clipboard
        case fileUrls([URL])
    }
    let kind: AssetType
    let source: Source
    let projectName: String
    let limit: Int
}

enum ImportPayload {
    case uiImages([UIImage])   // 에디터로 바로 넘길 때
    case fileUrls([URL])       // 디스크 원본 보존 흐름 (사운드/이미지 공통)
}

enum ImportError: Error {
    case nothingToImport
    case conversionFailed
    case ioFailed(Error)
}

protocol ImportStrategyInterface {
    /// 요청(Source)에 맞춰 NSItemProvider/PhotosPicker/Clipboard/URL → ImportPayload 로 변환
    /// - Parameter request: 가져오기 요청 정보(소스, 타입, 제한 개수, 프로젝트명 등)를 포함한 구조체.
    /// - Returns: 변환된 ImportPayload (예: 이미지 배열 또는 파일 URL 목록).
    func collect(_ request: ImportRequest) async throws -> ImportPayload
}
