//
//  TinyPinyin.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/9.
//

import Foundation

public final class Pinyin {
    
    nonisolated(unsafe)
    static var mTrieDict: Trie?
    nonisolated(unsafe)
    static var mSelector: SegmentationSelector?
    nonisolated(unsafe)
    static var mPinyinDicts: [PinyinDict]?

    private init() {}

    public final class Config {

        var mSelector: SegmentationSelector
        var mPinyinDicts: [PinyinDict]?

        fileprivate init(_ dicts: [PinyinDict]?) {
            if let dicts = dicts {
                self.mPinyinDicts = dicts
            }
            self.mSelector = ForwardLongestSelector()
        }

        // Add a dictionary and make chained calls
        @discardableResult
        public func with(_ dict: PinyinDict?) -> Config {
            guard let dict = dict else { return self }
            if mPinyinDicts == nil {
                mPinyinDicts = [dict]
            } else if !(mPinyinDicts!.contains { $0 as AnyObject === dict as AnyObject }) {
                mPinyinDicts!.append(dict)
            }
            return self
        }

        func valid() -> Bool {
            return getPinyinDicts() != nil && getSelector() != nil
        }

        func getSelector() -> SegmentationSelector? {
            return mSelector
        }

        func getPinyinDicts() -> [PinyinDict]? {
            return mPinyinDicts
        }
    }

    public static func newConfig() -> Config {
        return Config(mPinyinDicts)
    }

    /// Initialize Pinyin using Config (equivalent to pinyin.init (Config))
    ///
    /// Note: In Swift, "init" cannot be used as a static method name to avoid conflicts with constructors
    /// Here, initialize is used, and the calling method is Pinyin.initialize(config).
    public static func initialize(_ config: Config?) {
        guard let config = config else {
            // Clear the Settings
            mPinyinDicts = nil
            mTrieDict = nil
            mSelector = nil
            return
        }

        guard config.valid(), let dicts = config.getPinyinDicts() else {
            // Ignore invalid Config
            return
        }

        mPinyinDicts = dicts
        mTrieDict = Utils.dictsToTrie(dicts)
        mSelector = config.getSelector()
    }

    /// add a dictionary to Pinyin (equivalent to pinyin.add)
    public static func add(_ dict: PinyinDict?) {
        guard let dict = dict,
              !dict.words().isEmpty else {
            return
        }
        let cfg = Config(mPinyinDicts).with(dict)
        initialize(cfg)
    }

    // MARK: - String toPinyin(equivalent pinyin.topinyin (String, String))

    public static func toPinyin(_ str: String, separator: String) -> String {
        return Engine.toPinyin(
            str,
            trie: mTrieDict,
            pinyinDictList: mPinyinDicts,
            separator: separator,
            selector: mSelector
        )
    }

    // MARK: - Single-character toPinyin conversion (equivalent to pinyin.topinyin (char))

    public static func toPinyin(_ char: Character) -> String {
        if isChinese(char) {
            if let scalar = char.unicodeScalars.first {
                let value = scalar.value
                if value == PinyinData.CHAR_12295 {
                    return PinyinData.PINYIN_12295
                } else {
                    let code = getPinyinCode(forScalarValue: value)
                    if code > 0 && code < PinyinData.PINYIN_TABLE.count {
                        return PinyinData.PINYIN_TABLE[code]
                    }
                }
            }
        }
        return String(char)
    }

    // MARK: - Determine if it is a Chinese character (equivalent to Pinyin.isChinese)

    public static func isChinese(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value

        if value == PinyinData.CHAR_12295 {
            return true
        }

        if value < PinyinData.MIN_VALUE || value > PinyinData.MAX_VALUE {
            return false
        }

        let code = getPinyinCode(forScalarValue: value)
        return code > 0
    }

    // MARK: - Compressed table decoding (equivalent to getPinyinCode/decodeIndex)

    private static func getPinyinCode(forScalarValue value: UInt32) -> Int {
        let offset = Int(value - PinyinData.MIN_VALUE)
        if offset < 0 {
            return 0
        }
        if offset < PinyinData.PINYIN_CODE_1_OFFSET {
            return decodeIndex(
                paddings: PinyinCode1.PINYIN_CODE_PADDING,
                indexes: PinyinCode1.PINYIN_CODE,
                offset: offset
            )
        } else if offset < PinyinData.PINYIN_CODE_2_OFFSET {
            return decodeIndex(
                paddings: PinyinCode2.PINYIN_CODE_PADDING,
                indexes: PinyinCode2.PINYIN_CODE,
                offset: offset - PinyinData.PINYIN_CODE_1_OFFSET
            )
        } else {
            return decodeIndex(
                paddings: PinyinCode3.PINYIN_CODE_PADDING,
                indexes: PinyinCode3.PINYIN_CODE,
                offset: offset - PinyinData.PINYIN_CODE_2_OFFSET
            )
        }
    }

    private static func decodeIndex(
        paddings: [Int8],
        indexes: [Int8],
        offset: Int
    ) -> Int {
        let index1 = offset / 8
        let index2 = offset % 8

        // realIndex = indexes[offset] & 0xff
        var realIndex = Int(indexes[offset]) & 0xFF

        // If the paddings correspond to bit Settings, add 256
        let paddingBit = Int(paddings[index1]) & PinyinData.BIT_MASKS[index2]
        if paddingBit != 0 {
            realIndex |= PinyinData.PADDING_MASK
        }
        return realIndex
    }
}
