//
//  View+CircleButtonStyle.swift
//  Glayer
//
//  Created by jeongminji on 10/31/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func circleButtonStyle(_ style: CircleFillButtonStyle) -> some View {
        switch style {
        case .plain:
            self.buttonStyle(.plain)
        case .automatic:
            self.buttonStyle(.automatic)
        }
    }
}
