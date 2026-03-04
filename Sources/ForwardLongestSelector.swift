//
//  ForwardLongestSelector.swift
//  Galaxy
//
//  Created by gengjia lin on 2026/2/9.
//

public final class ForwardLongestSelector: SegmentationSelector {

    public init() {}

    public func select(_ emits: [Emit]?) -> [Emit]? {
        guard let emits = emits else { return nil }

        var results = emits

        // 等价 Engine.EmitComparator：
        // 起点小的在前；起点相同，长度大的在前
        results.sort { (o1, o2) -> Bool in
            if o1.start == o2.start {
                return o1.size > o2.size
            } else {
                return o1.start < o2.start
            }
        }

        var endValueToRemove = -1
        var toRemove = Set<Emit>()

        for emit in results {
            if emit.start > endValueToRemove && emit.end > endValueToRemove {
                endValueToRemove = emit.end
            } else {
                toRemove.insert(emit)
            }
        }

        results.removeAll { toRemove.contains($0) }
        return results
    }
}
