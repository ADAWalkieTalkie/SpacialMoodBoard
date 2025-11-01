//
//  ToastView.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI

struct ToastView: View {
    let text: String
    let subText: String
    
    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 2) {
                Text(text)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(subText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 25)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityAddTraits(.isStaticText)
    }
}
