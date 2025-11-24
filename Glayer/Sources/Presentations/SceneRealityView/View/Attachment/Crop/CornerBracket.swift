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
    let cornerRadius: CGFloat
    
    var body: some View {
        CornerBracketShape(length: length, cornerRadius: cornerRadius)
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
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let L = min(length, min(rect.width, rect.height))
        let r = min(cornerRadius, L / 2)

        let x0 = rect.minX
        let y0 = rect.minY
        
        path.move(to: CGPoint(x: x0, y: y0 + L))
        path.addLine(to: CGPoint(x: x0, y: y0 + r))
        path.addQuadCurve(
            to: CGPoint(x: x0 + r, y: y0),
            control: CGPoint(x: x0, y: y0)
        )
        path.addLine(to: CGPoint(x: x0 + L, y: y0))
        
        return path
    }
}
