//
//  ForwardLongestSelector.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/9.
//

public final class ForwardLongestSelector: SegmentationSelector {

    public init() {}

    public func select(_ emits: [Emit]?) -> [Emit]? {
        guard let emits = emits else { return nil }
        var results = emits

        // Equivalent Engine.EmitComparator:
        // The one with a smaller starting point comes first; When the starting points are the same, the longer one comes first
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
