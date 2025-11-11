//
//  ToastView.swift
//  Glayer
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI
import Lottie

struct ToastView: View {
    let message: ToastMessage
    let dismissAction: (() -> Void)?
    
    private let kpFillColor = AnimationKeypath(keys: ["**", "Fill 1", "Color"])
    private let primaryColor =  UIColor(red: 217/255.0, green: 217/255.0, blue: 217/255.0, alpha: 1.0)
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 24) {
                if let ani = message.animationName, message.animationName != nil {
                    LottieView {
                        LottieAnimation.named(ani, bundle: .main)
                    }
                    .resizable()
                    .intrinsicSize()
                    .looping()
                    .valueProvider(ColorValueProvider(primaryColor.lottieColorValue), for: kpFillColor)
                    .frame(width: 28, height: 32)
                }
                
                VStack(alignment: .center, spacing: 2) {
                    Text(message.title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    if let sub = message.subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, message.animationName != nil ? 16 : 4)
                .padding(.vertical, 8)
            }
            
            if case .manual = message.dismissMode {
                Button(action: { dismissAction?() }) {
                    Text(String(localized: "action.confirm"))
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 99)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .clipShape(Capsule())
                .contentShape(Capsule())
            }
        }
        .padding(.horizontal, message.animationName != nil ? 44 : 25)
        .padding(.vertical, message.animationName != nil ? 24 : 25)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .accessibilityAddTraits(.isStaticText)
    }
}
