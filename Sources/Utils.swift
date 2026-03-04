//
//  UtilsSwift.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/9.
//

struct Utils {
    static func dictsToTrie(_ pinyinDicts: [PinyinDict]?) -> Trie? {
        var all = Set<String>()
        let builder = Trie.Builder()
        if let dicts = pinyinDicts {
            for dict in dicts {
                let ws = dict.words()
                all.formUnion(ws)
            }
            if !all.isEmpty {
                // Sorted order to match Android TreeSet (deterministic Trie build)
                for key in all.sorted() {
                    builder.addKeyword(key)
                }
                return builder.build()
            }
        }
        return nil
    }
}
