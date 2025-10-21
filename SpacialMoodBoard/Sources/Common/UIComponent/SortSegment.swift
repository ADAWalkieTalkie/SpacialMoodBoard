//
//  SortSegment.swift
//  SpacialMoodBoard
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI

struct SortSegment: View {
    @Binding var selection: SortOrder

    var body: some View {
        Picker("정렬", selection: $selection) {
            ForEach(SortOrder.allCases) { mode in
                Text(mode.title)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
