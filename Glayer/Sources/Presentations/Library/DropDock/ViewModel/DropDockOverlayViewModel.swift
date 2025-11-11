//
//  DropDockOverlayViewModel.swift
//  Glayer
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI
import PhotosUI

@Observable
final class DropDockOverlayViewModel {

    // MARK: - Properties
    
    private(set) var isTargeted: Bool = false
    var photoSelection: [PhotosPickerItem] = []
    
    private let onDrop: ([NSItemProvider]) -> Void
    private let onPhotosPicked: ([PhotosPickerItem]) -> Void
    private let onPaste: () -> Void
    
    // MARK: - Init
    
    /// 드롭 도크 오버레이에서 발생한 입력 이벤트들을 상위로 포워딩하는 뷰모델
    /// - Parameters:
    ///   - onDrop: 드래그&드롭으로 전달된 `NSItemProvider` 배열을 상위로 전달하는 콜백
    ///   - onPhotosPicked: PhotosPicker에서 선택된 항목 배열을 상위로 전달하는 콜백
    ///   - onPaste: 클립보드 붙여넣기 트리거를 상위로 알리는 콜백
    init(
            onDrop: @escaping ([NSItemProvider]) -> Void,
            onPhotosPicked: @escaping ([PhotosPickerItem]) -> Void,
            onPaste: @escaping () -> Void
        ) {
            self.onDrop = onDrop
            self.onPhotosPicked = onPhotosPicked
            self.onPaste = onPaste
        }

    // MARK: - Methods
    
    /// 드롭 타깃 영역에 포인터가 진입/이탈했는지 상태를 갱신
    /// - Parameter targeted: 타깃 위에 있을 때 `true`, 벗어나면 `false`
    func setDropTargeted(_ targeted: Bool) { isTargeted = targeted }
    
    /// 드래그&드롭으로 전달된 항목들을 상위 콜백으로 전달
    /// - Parameter providers: 드롭된 `NSItemProvider` 배열(최대 10개로 제한되어 전달됨)
    /// - Returns: 항상 `true`를 반환합니다(전달 시도 완료 의미)
    @discardableResult
    func handleOnDrop(providers: [NSItemProvider]) -> Bool {
        onDrop(Array(providers.prefix(10)))
        return true
    }
    
    /// PhotosPicker 선택 변경을 처리하여 상위로 전달
    /// - Parameter limit: 최대 전달 개수(기본 10). 선택 목록을 이 개수로 잘라 전다
    func handlePhotosChanged(limit: Int = 10) async {
        guard !photoSelection.isEmpty else { return }
        let items = Array(photoSelection.prefix(limit))
        onPhotosPicked(items)
        photoSelection.removeAll()
    }
    
    /// 클립보드 붙여넣기 동작을 상위로 알림
    func pasteFromClipboard() { onPaste() }
}


