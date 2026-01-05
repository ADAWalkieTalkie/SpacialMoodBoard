//
//  CapsuleTextButtonEnum.swift
//  Glayer
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI

enum CapsuleTextButtonEnum {
    case imageEditorView
    case dropDockOverlayView
    case cropCancel
    case cropComplete

    var font: Font {
        switch self {
        case .imageEditorView:
            return .system(size: 17, weight: .medium)
        case .dropDockOverlayView:
            return .system(size: 19, weight: .medium)
        case .cropCancel, .cropComplete:
            return .system(size: 17, weight: .medium)
        }
    }

    var fontColor: Color {
        switch self {
        case .imageEditorView:
            return .primary
        case .dropDockOverlayView:
            return .primary
        case .cropCancel:
            return .red
        case .cropComplete:
            return .white
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .imageEditorView:
            return 11
        case .dropDockOverlayView:
            return 6.5
        case .cropCancel, .cropComplete:
            return 17.5
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .imageEditorView:
            return 16
        case .dropDockOverlayView:
            return 26
        case .cropCancel, .cropComplete:
            return 24
        }
    }

    var background: AnyShapeStyle {
        switch self {
        case .imageEditorView:
            return AnyShapeStyle(.ultraThinMaterial)
        case .dropDockOverlayView:
            return AnyShapeStyle(.black.opacity(0.26))
        case .cropCancel, .cropComplete:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }
}
