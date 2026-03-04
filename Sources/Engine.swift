//
//  EngineSwift.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/9.
//

struct Engine {

    static func toPinyin(
        _ inputStr: String,
        trie: Trie?,
        pinyinDictList: [PinyinDict]?,
        separator: String,
        selector: SegmentationSelector?
    ) -> String {
        if inputStr.isEmpty {
            return inputStr
        }

        if trie == nil || selector == nil {
            // Just like Java: No dictionary or selector is provided, output by single-character conversion
            var buf: [String] = []
            buf.reserveCapacity(inputStr.count)
            for (i, ch) in inputStr.enumerated() {
                buf.append(Pinyin.toPinyin(ch))
                if i != inputStr.count - 1 {
                    buf.append(separator)
                }
            }
            return buf.joined()
        }

        let emits = trie!.parseText(inputStr)
        let selectedEmits = selector!.select(emits) ?? []

        // Sort using the same comparator
        let sortedEmits = selectedEmits.sorted { (o1, o2) -> Bool in
            if o1.start == o2.start {
                return o1.size > o2.size
            } else {
                return o1.start < o2.start
            }
        }

        var resultBuf: [String] = []
        resultBuf.reserveCapacity(inputStr.count * 2)

        let chars = Array(inputStr)
        var nextHitIndex = 0
        var i = 0

        while i < chars.count {
            if nextHitIndex < sortedEmits.count,
               i == sortedEmits[nextHitIndex].start {

                let word = sortedEmits[nextHitIndex].keyword
                let fromDicts = pinyinFromDict(wordInDict: word, pinyinDictSet: pinyinDictList)

                for (j, p) in fromDicts.enumerated() {
                    resultBuf.append(p.uppercased())
                    if j != fromDicts.count - 1 {
                        resultBuf.append(separator)
                    }
                }

                i += sortedEmits[nextHitIndex].size
                nextHitIndex += 1
            } else {
                // Convert the i-th character to pinyin
                resultBuf.append(Pinyin.toPinyin(chars[i]))
                i += 1
            }

            if i != chars.count {
                resultBuf.append(separator)
            }
        }

        return resultBuf.joined()
    }

    static func pinyinFromDict(
        wordInDict: String,
        pinyinDictSet: [PinyinDict]?
    ) -> [String] {
        if let dicts = pinyinDictSet {
            for dict in dicts {
                let ws = dict.words()
                if ws.contains(wordInDict),
                   let py = dict.toPinyin(wordInDict),
                   !py.isEmpty {
                    return py
                }
            }
        }
        fatalError("No pinyin dict contains word: \(wordInDict)")
    }
}
