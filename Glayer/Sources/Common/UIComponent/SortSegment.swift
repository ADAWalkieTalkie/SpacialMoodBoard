//
//  SortSegment.swift
//  Glayer
//
//  Created by jeongminji on 10/21/25.
//

import SwiftUI

struct SortSegment: View {

    // MARK: - Properties
    
    enum Group { case sort, origin }

    @Binding private var selectionAll: SortOrder
    private let group: Group

    private var options: [SortOrder] {
        switch group {
        case .sort:   return SortOrder.Sort.allCases.map(SortOrder.sort)
        case .origin: return SortOrder.Origin.allCases.map(SortOrder.origin)
        }
    }

    private var coercedSelection: Binding<SortOrder> {
        Binding(
            get: { options.contains(selectionAll) ? selectionAll : (options.first ?? selectionAll) },
            set: { selectionAll = $0 }
        )
    }

    // MARK: - Init
    
    /// 통합형 `SortOrder` 바인딩을 사용하는 초기화 메서드
    /// - Parameters:
    ///   - selection: 전체 선택 상태를 나타내는 바인딩
    ///   - group: 세그먼트 그룹 (.sort 또는 .origin)
    init(selection: Binding<SortOrder>, group: Group) {
        self._selectionAll = selection
        self.group = group
        
        if !options.contains(selection.wrappedValue), let first = options.first {
            self._selectionAll.wrappedValue = first
        }
    }
    
    /// 정렬용(`SortOrder.Sort`) 전용 초기화 메서드
    /// - Parameter selection: 정렬 상태 바인딩 (.recent / .nameAZ)
    init(sort selection: Binding<SortOrder.Sort>) {
        self.group = .sort
        self._selectionAll = Binding<SortOrder>(
            get: { .sort(selection.wrappedValue) },
            set: { newValue in
                if case let .sort(s) = newValue { selection.wrappedValue = s }
            }
        )
    }
    
    /// 출처용(`SortOrder.Origin`) 전용 초기화 메서드
    /// - Parameter selection: 출처 상태 바인딩 (.basicOnly / .userOnly)
    init(origin selection: Binding<SortOrder.Origin>) {
        self.group = .origin
        self._selectionAll = Binding<SortOrder>(
            get: { .origin(selection.wrappedValue) },
            set: { newValue in
                if case let .origin(o) = newValue { selection.wrappedValue = o }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        Picker(String(localized: "mode.label"), selection: coercedSelection) {
            ForEach(options) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
