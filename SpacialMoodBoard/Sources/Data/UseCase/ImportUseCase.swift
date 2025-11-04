//
//  ImportUseCase.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/2/25.
//

import UIKit

enum ImportResult {
    case images([UIImage])
    case soundsSaved
}

final class ImportUseCase {
    
    // MARK: - Properties
    
    private let assetRepository: AssetRepositoryInterface
    
    // MARK: - Init
    
    /// 에셋 저장소를 주입받아 임포트 유즈케이스를 초기화
    /// - Parameter assetRepository: 이미지/사운드 데이터를 영속화할 `AssetRepositoryInterface`
    init(assetRepository: AssetRepositoryInterface) {
        self.assetRepository = assetRepository
    }
    
    // MARK: - Methods
    
    /// 임포트 요청을 처리합니다. 소스에 맞는 전략으로 페이로드를 수집하고, 종류(이미지/사운드)에 따라 결과를 반환
    /// - Parameter request: 소스(드래그&드롭/포토피커/클립보드/파일URL), 종류(이미지/사운드), 제한 개수 등을 포함한 요청
    /// - Returns: 이미지인 경우 `.images([UIImage])`, 사운드인 경우 `.soundsSaved`
    /// - Throws: 소스에 가져올 항목이 없거나 변환 실패, 파일 I/O/저장 중 오류가 발생하면 에러를 던지
    func execute(_ request: ImportRequest) async throws -> ImportResult {
        let strategy: ImportStrategyInterface = {
            switch request.source {
            case .dragDrop:
                return DragDropStrategy()
            case .photosPicker:
                return PhotoPickerStrategy()
            case .clipboard:
                return ClipboardStrategy()
            case .fileUrls:
                return FileUrlsStrategy()
            }
        }()
        
        let payload = try await strategy.collect(request)
        switch request.kind {
        case .image:
            guard case let .uiImages(images) = payload else { throw ImportError.conversionFailed }
            return .images(images)
            
        case .sound:
            guard case let .fileUrls(urls) = payload else {
                throw ImportError.conversionFailed
            }
            try await saveSounds(urls)
            return .soundsSaved
        }
    }
    
    // MARK: - Private Methods
    
    /// 허용된 확장자의 사운드 파일들을 프로젝트에 원본 그대로 저장
    /// - Parameter urls: 사용자가 선택한 사운드 파일 URL 배열
    private func saveSounds(_ urls: [URL]) async throws {
        let allowed = Set(["mp3","m4a","wav","aac","caf"])
        for url in urls where allowed.contains(url.pathExtension.lowercased()) {
            let needs = url.startAccessingSecurityScopedResource()
            defer { if needs { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            _ = try await assetRepository.addSoundData(data, filename: url.lastPathComponent)
        }
    }
}
