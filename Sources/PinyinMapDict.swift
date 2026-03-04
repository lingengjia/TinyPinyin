//
//  PinyinMapDict.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/9.
//

import Foundation

// MARK: - PinyinDict Protocol & Map implementation

public protocol PinyinDict {
    func words() -> Set<String>
    func toPinyin(_ word: String) -> [String]?
}

open class PinyinMapDict: PinyinDict {

    public init() {}

    /// Corresponding to Java's mapping()
    open func mapping() -> [String: [String]] {
        fatalError("Subclasses must override mapping()")
    }

    public func words() -> Set<String> {
        return Set(mapping().keys)
    }

    public func toPinyin(_ word: String) -> [String]? {
        return mapping()[word]
    }
}
