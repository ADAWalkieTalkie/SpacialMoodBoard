//
//  CornerBracket.swift
//  Glayer
//
//  Created by jeongminji on 11/14/25.
//

import SwiftUI

struct CornerBracket: View {
    let length: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        CornerBracketShape(length: length)
            .stroke(
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: length, height: length, alignment: .topLeading)
    }
}

struct CornerBracketShape: Shape {
    var length: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let L = min(length, min(rect.width, rect.height))
        
        let x0 = rect.minX
        let y0 = rect.minY
        
        path.move(to: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x0, y: y0 + L))
        
        path.move(to: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x0 + L, y: y0))
        
        return path
    }
}
