//
//  Color+.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 11/1/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let v = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0
        let r, g, b: Double
        switch hex.count {
        case 3: /// RGB (12-bit)
            r = Double((v >> 8) & 0xF) / 15.0
            g = Double((v >> 4) & 0xF) / 15.0
            b = Double(v & 0xF) / 15.0
        default: /// RGB (24-bit)
            r = Double((v >> 16) & 0xFF) / 255.0
            g = Double((v >> 8) & 0xFF) / 255.0
            b = Double(v & 0xFF) / 255.0
        }
        self = Color(red: r, green: g, blue: b)
    }
}
