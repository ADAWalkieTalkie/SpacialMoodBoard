//
//  ToastMessage.swift
//  Glayer
//
//  Created by jeongminji on 11/8/25.
//

import SwiftUI

enum ToastMessage {
    case addToLibrary
    case addToLibraryFail
    case loadingError
    case loadingImageEdit
    case loadingAssets
    case addToVolume
    
    var title: String {
        switch self {
        case .addToLibrary:
            return String(localized: "toast.addToLibrary.title")
        case .addToLibraryFail:
            return String(localized: "toast.addToLibraryFail.title")
        case .loadingError:
            return String(localized: "toast.loadingError.title")
        case .loadingImageEdit:
            return String(localized: "toast.loadingImageEdit.title")
        case .loadingAssets:
            return String(localized: "toast.loadingAssets.title")
        case .addToVolume:
            return String(localized: "toast.addToVolume.title")
        }
    }
    
    var titleFont: Font {
        switch self {
        case .addToVolume:
            return .system(size: 19, weight: .medium)
        default:
            return .system(size: 19, weight: .bold)
        }
    }
    
    var subtitle: String? {
        switch self {
        case .addToLibrary:
            return String(localized: "toast.addToLibrary.subtitle")
        case .addToLibraryFail:
            return String(localized: "toast.addToLibraryFail.subtitle")
        case .loadingError:
            return String(localized: "toast.loadingError.subtitle")
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
    
    var image: Image? {
        switch self {
        case .addToVolume:
            return Image(systemName: "checkmark.circle")
        default:
            return nil
        }
    }
    
    var position: ToastPosition {
        switch self {
        case .addToVolume:
            return .bottom
        default:
            return .center
        }
    }
    
    var dismissMode: ToastDismissMode {
        switch self {
        case .loadingError:
            return .manual
        case .loadingImageEdit, .loadingAssets:
            return .external()
        default:
            return .auto(duration: 1.3)
        }
    }
    
    var textPadding: (h: CGFloat, v: CGFloat) {
        switch self {
        case .loadingAssets:
            return (16, 8)
        case .addToVolume:
            return (0,  0)
        default:
            return (4, 8)
        }
    }
    
    var bodyPadding: (h: CGFloat, v: CGFloat) {
        switch self {
        case .loadingAssets:
            return (24, 24)
        case .addToVolume:
            return (24,  20)
        default:
            return (25, 25)
        }
    }
}
