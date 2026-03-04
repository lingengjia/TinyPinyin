//
//  SegmentationSelector.swift
//  Galaxy
//
//  Created by gengjia lin on 2026/2/9.
//

public protocol SegmentationSelector {
    func select(_ emits: [Emit]?) -> [Emit]?
}
