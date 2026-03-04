// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  TinyPinyin.swift
//  note-core
//
//  Created by gengjia lin on 2026/2/9.
//

import Foundation

public final class Pinyin {

    // MARK: - 对应 Java 的静态字段
    nonisolated(unsafe)
    static var mTrieDict: Trie?
    nonisolated(unsafe)
    static var mSelector: SegmentationSelector?
    nonisolated(unsafe)
    static var mPinyinDicts: [PinyinDict]?

    private init() {}

    // MARK: - Config（等价 Pinyin.Config）

    public final class Config {

        var mSelector: SegmentationSelector
        var mPinyinDicts: [PinyinDict]?

        fileprivate init(_ dicts: [PinyinDict]?) {
            if let dicts = dicts {
                self.mPinyinDicts = dicts
            }
            self.mSelector = ForwardLongestSelector()
        }

        /// 添加字典，链式调用
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

    /// 返回新的 Config 对象（等价 Pinyin.newConfig）
    public static func newConfig() -> Config {
        return Config(mPinyinDicts)
    }

    /// 使用 Config 初始化 Pinyin（等价 Pinyin.init(Config)）
    ///
    /// 注意：Swift 里不能用“init”做静态方法名，避免和构造器冲突，
    /// 这里用 initialize，调用方式是 Pinyin.initialize(config)
    public static func initialize(_ config: Config?) {
        guard let config = config else {
            // 清空设置
            mPinyinDicts = nil
            mTrieDict = nil
            mSelector = nil
            return
        }

        guard config.valid(), let dicts = config.getPinyinDicts() else {
            // 忽略无效 Config
            return
        }

        mPinyinDicts = dicts
        mTrieDict = Utils.dictsToTrie(dicts)
        mSelector = config.getSelector()
    }

    /// 向 Pinyin 中追加词典（等价 Pinyin.add）
    public static func add(_ dict: PinyinDict?) {
        guard let dict = dict,
              !dict.words().isEmpty else {
            return
        }
        let cfg = Config(mPinyinDicts).with(dict)
        initialize(cfg)
    }

    // MARK: - 字符串转拼音（等价 Pinyin.toPinyin(String, String)）

    public static func toPinyin(_ str: String, separator: String) -> String {
        return Engine.toPinyin(
            str,
            trie: mTrieDict,
            pinyinDictList: mPinyinDicts,
            separator: separator,
            selector: mSelector
        )
    }

    // MARK: - 单字符转拼音（等价 Pinyin.toPinyin(char)）

    public static func toPinyin(_ c: Character) -> String {
        if isChinese(c) {
            if let scalar = c.unicodeScalars.first {
                let v = scalar.value
                if v == PinyinData.CHAR_12295 {
                    return PinyinData.PINYIN_12295
                } else {
                    let code = getPinyinCode(forScalarValue: v)
                    if code > 0 && code < PinyinData.PINYIN_TABLE.count {
                        return PinyinData.PINYIN_TABLE[code]
                    }
                }
            }
        }
        return String(c)
    }

    // MARK: - 判断是否汉字（等价 Pinyin.isChinese）

    public static func isChinese(_ c: Character) -> Bool {
        guard let scalar = c.unicodeScalars.first else { return false }
        let v = scalar.value

        if v == PinyinData.CHAR_12295 {
            return true
        }

        if v < PinyinData.MIN_VALUE || v > PinyinData.MAX_VALUE {
            return false
        }

        let code = getPinyinCode(forScalarValue: v)
        return code > 0
    }

    // MARK: - 压缩表解码（等价 getPinyinCode / decodeIndex）

    private static func getPinyinCode(forScalarValue v: UInt32) -> Int {
        let offset = Int(v - PinyinData.MIN_VALUE)

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

        // 如果 paddings 对应 bit 置位，则加上 256
        let paddingBit = Int(paddings[index1]) & PinyinData.BIT_MASKS[index2]
        if paddingBit != 0 {
            realIndex |= PinyinData.PADDING_MASK
        }

        return realIndex
    }
}
