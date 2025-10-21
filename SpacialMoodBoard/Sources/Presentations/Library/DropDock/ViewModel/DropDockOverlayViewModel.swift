//
//  DropDockOverlayViewModel.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI
import PhotosUI


@MainActor
@Observable
final class DropDockOverlayViewModel {

    // MARK: - Properties
    
    private(set) var isTargeted: Bool = false
    private(set) var pasteError: String?
    var photoSelection: [PhotosPickerItem] = []
    var showFileImporter: Bool = false

    private let sendProviders: ([NSItemProvider]) -> Bool
    private let onSuccess: () -> Void

    // MARK: - Init
    
    /// - Parameters:
    ///   - sendProviders: 상위로 `NSItemProvider` 배열을 전달(=기존 `onDropProviders`)하는 콜백
    ///   - onSuccess: 성공적으로 전달되면 오버레이를 닫기 위한 콜백
    init(
        sendProviders: @escaping ([NSItemProvider]) -> Bool,
        onSuccess: @escaping () -> Void
    ) {
        self.sendProviders = sendProviders
        self.onSuccess = onSuccess
    }

    // MARK: - Methods
    
    /// 드롭 타깃 진입/이탈 상태를 업데이트
    /// - Parameter targeted: 타깃 위에 있는 경우 `true`, 벗어난 경우 `false`
    func setDropTargeted(_ targeted: Bool) {
        isTargeted = targeted
    }

    /// onDrop 제스처로 전달된 아이템들을 상위로 넘겨 처리.
    /// - Parameter providers: 드롭된 `NSItemProvider` 목록.
    /// - Returns: 상위 처리 성공 여부. 성공 시 `onSuccess()`를 호출해 오버레이를 닫음
    @discardableResult
    func handleOnDrop(providers: [NSItemProvider]) -> Bool {
        let ok = sendProviders(Array(providers.prefix(10)))
        if ok { onSuccess() } else { pasteError = "가져오기 처리에 실패했어요." }
        return ok
    }
    
    /// 파일 선택기를 열도록 플래그를 설정
    func openFiles() {
        showFileImporter = true
    }

    /// 파일 선택기에서 고른 파일 URL들을 `NSItemProvider`로 감싸 상위로 전달
    /// - Parameter urls: 사용자가 선택한 파일 URL 배열
    func handleFilesPicked(urls: [URL]) {
        let providers = Array(urls.prefix(10)).compactMap { NSItemProvider(contentsOf: $0) }
        finish(with: providers)
    }
    
    ///  포토 피커의 선택 변경을 처리. 최대 `limit`개만 수용하며, Data → 임시 파일 URL → NSItemProvider 순서로 변환 후 상위로 전달
    /// - Parameter limit: 최대 처리 개수(기본 10).
    func handlePhotosChanged(limit: Int = 10) async {
        guard !photoSelection.isEmpty else { return }
        let items = Array(photoSelection.prefix(limit))
        var providers: [NSItemProvider] = []

        for item in items {
            /// 1) Data → temp url
            if let data = try? await item.loadTransferable(type: Data.self),
               let url = writeTemp(data: data, ext: "png"),
               let p = NSItemProvider(contentsOf: url) {
                providers.append(p)
                continue
            }
            /// 2) URL 직접 제공
            if let url = try? await item.loadTransferable(type: URL.self),
               let p = NSItemProvider(contentsOf: url) {
                providers.append(p)
                continue
            }
        }

        if providers.isEmpty {
            pasteError = "선택한 사진을 가져오지 못했어요."
        } else {
            finish(with: providers)
        }

        photoSelection.removeAll()
    }

    /// 클립보드에서 이미지/URL을 감지하여 상위로 전달.
    /// 우선순위: `image` → `image data` → `url` → `string→URL`
    /// 실패 시 `pasteError`를 설정
    func pasteFromClipboard() {
        var providers: [NSItemProvider] = []

        /// 1) 이미지 객체
        if let img = UIPasteboard.general.image {
            providers = [NSItemProvider(object: img)]
            finish(with: providers); return
        }

        /// 2) 바이너리 이미지
        if let data = UIPasteboard.general.data(forPasteboardType: UTType.image.identifier),
           let url = writeTemp(data: data, ext: "png"),
           let p = NSItemProvider(contentsOf: url) {
            providers = [p]
            finish(with: providers); return
        }

        /// 3) URL (file/http)
        if let url = UIPasteboard.general.url,
           let p = NSItemProvider(contentsOf: url) {
            providers = [p]
            finish(with: providers); return
        }

        /// 4) 문자열 → URL
        if let s = UIPasteboard.general.string,
           let url = URL(string: s),
           let p = NSItemProvider(contentsOf: url) {
            providers = [p]
            finish(with: providers); return
        }

        pasteError = "클립보드에서 가져올 이미지/URL이 없어요."
    }

    // MARK: - Private Methods
    
    /// 변환된 `NSItemProvider` 배열을 상위로 전달하고, 성공 시 오버레이를 닫고, 실패 시 오류 메시지를 기록
    /// - Parameter providers: 상위로 넘길 `NSItemProvider` 배열
    private func finish(with providers: [NSItemProvider]) {
        let ok = sendProviders(Array(providers.prefix(10)))
        if ok { onSuccess() }
        else { pasteError = "가져오기 처리에 실패했어요." }
    }
    
    /// 임시 디렉터리에 파일을 생성하여 URL을 반환
    /// - Parameters:
    ///   - data: 저장할 원본 데이터
    ///   - ext: 확장자(예: "png", "jpg")
    /// - Returns: 저장에 성공하면 임시 파일 URL, 실패 시 `nil`과 함께 `pasteError` 설정
    private func writeTemp(data: Data, ext: String) -> URL? {
        let name = UUID().uuidString + "." + ext
        do {
            let dir = try FileManager.default.url(for: .cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let url = dir.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            pasteError = "임시 파일 저장 실패"
            return nil
        }
    }
}


