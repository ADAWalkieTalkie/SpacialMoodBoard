//
//  ToastMessage.swift
//  Glayer
//
//  Created by jeongminji on 11/8/25.
//

enum ToastMessage {
    case addToLibrary
    case addToLibraryFail
    case loadingError
    case loadingImageEdit
    case loadingAssets
    
    var title: String {
        switch self {
        case .addToLibrary:
            return "에셋 추가 완료"
        case .addToLibraryFail:
            return "에셋 추가 실패"
        case .loadingError:
            return "불러오기 오류"
        case .loadingImageEdit:
            return "이미지 편집 준비 중"
        case .loadingAssets:
            return "에셋 불러오는 중"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .addToLibrary:
            return "에셋이 라이브러리에 저장되었습니다."
        case .addToLibraryFail:
            return "라이브러리 저장에 실패했습니다."
        case .loadingError:
            return "에셋을 불러오는데 실패했습니다."
        default:
            return nil
        }
    }
    
    var sfx: SFX? {
        switch self {
        case .addToLibrary:
            return .addToLibrary
        default:
            return nil
        }
    }
    
    var animationName: String? {
        switch self {
        case .loadingImageEdit, .loadingAssets:
            return "LoadingDots"
        default:
            return nil
        }
    }
    
    var position: ToastPosition {
        switch self {
        default:
                .center
        }
    }
    
    var dismissMode: ToastDismissMode {
        switch self {
        case .addToLibrary, .addToLibraryFail:
            return .auto(duration: 1.3)
        case .loadingError:
            return .manual
        case .loadingImageEdit, .loadingAssets:
            return .external()
        }
    }
}
