//
//  PinyinDictDemoTests.swift
//  TinyPinyinDemo
//
//  Created by gengjia lin on 2026/3/4.
//

import Foundation
import TinyPinyin

struct PinyinDictDemoTestResult {
    let name: String
    let passed: Bool
    let message: String
}

struct TestMapDict: PinyinDict, @unchecked Sendable {
    let map: [String: [String]]
    nonisolated func words() -> Set<String> {
        Set(map.keys)
    }

    nonisolated func toPinyin(_ word: String) -> [String]? {
        map[word]
    }
}

struct PinyinDictDemoTests {

    /// 运行全部测试，返回 (通过数, 失败数, 详情)
    nonisolated static func runAll() -> (passed: Int, failed: Int, results: [PinyinDictDemoTestResult]) {
        var results: [PinyinDictDemoTestResult] = []
        let allCases: [() -> PinyinDictDemoTestResult] = [
            testInitWithNull,
            testInitWithNewConfig,
            testInitWithDict,
            testAddNullToNull,
            testAddNewDict,
            testToPinyinCharChinese,
            testToPinyinCharNonChinese,
            testToPinyinStringNoDict,
            testToPinyinStringWithDict,
            testIsChinese,
            testConfigStoredCopy,
            testToPinyinWithZeroDict,
            testToPinyinWithOneDict,
            testToPinyinFirstDictWins,
            testToPinyinEmptyString,
            testSelectSingleHit,
            testSelectMultiHitNoOverlap,
            testSelectMultiHitWithOverlap,
            testSelectNullReturnsNil,
            testWordsNonnullMapReturnsKeys,
            testToPinyinNonnullMapReturnsValue,
            testToPinyinNonnullMapNoKeyReturnsNil,
            testInitWithEmptyConfigNoDict,
            testInitWithDictBuildsTrie,
            testKeywordsSortedOrderDeterministic,
        ]
        for run in allCases {
            Pinyin.initialize(nil)
            let r = run()
            results.append(r)
        }
        let passed = results.filter(\.passed).count
        let failed = results.count - passed
        
        print("========== TinyPinyin 测试 ==========")
        print("通过 \(passed) / 失败 \(failed) / 共 \(results.count)")
        if failed > 0 {
            for r in results where !r.passed {
                print("  ✗ \(r.name): \(r.message)")
            }
        } else {
            print("全部通过 ✓")
        }
        print("=====================================")
        return (passed, failed, results)
    }

    private nonisolated static func ok(_ name: String) -> PinyinDictDemoTestResult {
        PinyinDictDemoTestResult(name: name, passed: true, message: "")
    }

    private nonisolated static func fail(_ name: String,
                                         _ msg: String) -> PinyinDictDemoTestResult {
        PinyinDictDemoTestResult(name: name, passed: false, message: msg)
    }

    /// 通用：条件为 true 则通过，否则失败
    private nonisolated static func check(_ name: String,
                                          _ condition: Bool,
                                          _ msg: String = "") -> PinyinDictDemoTestResult {
        condition ? ok(name) : fail(name, msg)
    }

    /// 通用：无词典/带词典 toPinyin 后与期望字符串比较（runAll 已在每次 test 前 init(nil)，此处不再重复）
    private nonisolated static func assertToPinyin(_ name: String,
                                                   input: String,
                                                   sep: String,
                                                   expected: String,
                                                   dict: PinyinDict? = nil) -> PinyinDictDemoTestResult {
        if let dict = dict {
            Pinyin.initialize(Pinyin.newConfig().with(dict))
        }
        let r = Pinyin.toPinyin(input, separator: sep)
        return check(name,
                     r == expected,
                     "expected '\(expected)' got '\(r)'")
    }

    // MARK: - Pinyin

    private nonisolated static func testInitWithNull() -> PinyinDictDemoTestResult {
        assertToPinyin("testInitWithNull",
                       input: "中",
                       sep: "",
                       expected: "ZHONG")
    }

    private nonisolated static func testInitWithNewConfig() -> PinyinDictDemoTestResult {
        Pinyin.initialize(Pinyin.newConfig())
        let r = Pinyin.toPinyin("中", separator: "")
        return check("testInitWithNewConfig",
                     r == "ZHONG",
                     "got \(r)")
    }

    private nonisolated static func testInitWithDict() -> PinyinDictDemoTestResult {
        assertToPinyin("testInitWithDict",
                       input: "重庆",
                       sep: ",",
                       expected: "CHONG,QING",
                       dict: TestMapDict(map: ["重庆": ["CHONG", "QING"]]))
    }

    private nonisolated static func testAddNullToNull() -> PinyinDictDemoTestResult {
        Pinyin.add(nil)
        return assertToPinyin("testAddNullToNull",
                              input: "中",
                              sep: "",
                              expected: "ZHONG")
    }

    private nonisolated static func testAddNewDict() -> PinyinDictDemoTestResult {
        Pinyin.initialize(Pinyin.newConfig().with(TestMapDict(map: ["重庆": ["CHONG", "QING"]])))
        Pinyin.add(TestMapDict(map: ["长安": ["CHANG", "AN"]]))
        let a = Pinyin.toPinyin("重庆", separator: ",")
        let b = Pinyin.toPinyin("长安", separator: ",")
        return check("testAddNewDict",
                     a == "CHONG,QING" && b == "CHANG,AN",
                     "重庆=\(a) 长安=\(b)")
    }

    private nonisolated static func testToPinyinCharChinese() -> PinyinDictDemoTestResult {
        let a = Pinyin.toPinyin("中"), b = Pinyin.toPinyin("国")
        return check("testToPinyinCharChinese",
                     a == "ZHONG" && b == "GUO",
                     "\(a) \(b)")
    }

    private nonisolated static func testToPinyinCharNonChinese() -> PinyinDictDemoTestResult {
        let a = Pinyin.toPinyin("A"), b = Pinyin.toPinyin("1")
        return check("testToPinyinCharNonChinese",
                     a == "A" && b == "1",
                     "\(a) \(b)")
    }

    private nonisolated static func testToPinyinStringNoDict() -> PinyinDictDemoTestResult {
        assertToPinyin("testToPinyinStringNoDict",
                       input: "中国",
                       sep: " ",
                       expected: "ZHONG GUO")
    }

    private nonisolated static func testToPinyinStringWithDict() -> PinyinDictDemoTestResult {
        assertToPinyin("testToPinyinStringWithDict",
                       input: "重庆和长安",
                       sep: ",",
                       expected: "CHONG,QING,HE,CHANG,AN",
                       dict: TestMapDict(map: ["重庆": ["CHONG", "QING"],
                                               "长安": ["CHANG", "AN"]]))
    }

    private nonisolated static func testIsChinese() -> PinyinDictDemoTestResult {
        let c1 = Pinyin.isChinese("中") && Pinyin.isChinese("国")
        let c2 = !Pinyin.isChinese("A") && !Pinyin.isChinese("1")
        return check("testIsChinese",
                     c1 && c2,
                     "isChinese result wrong")
    }

    private nonisolated static func testConfigStoredCopy() -> PinyinDictDemoTestResult {
        var dictList: [PinyinDict] = [TestMapDict(map: ["重": ["ZHONG"]])]
        Pinyin.initialize(Pinyin.newConfig().with(dictList[0]))
        dictList.removeAll()
        let r = Pinyin.toPinyin("重", separator: "")
        return check("testConfigStoredCopy",
                     r == "ZHONG",
                     "got \(r)")
    }

    // MARK: - Engine

    private nonisolated static func testToPinyinWithZeroDict() -> PinyinDictDemoTestResult {
        assertToPinyin("testToPinyinWithZeroDict",
                       input: "重庆和长安都很棒!",
                       sep: ",",
                       expected: "ZHONG,QING,HE,ZHANG,AN,DOU,HEN,BANG,!")
    }

    private nonisolated static func testToPinyinWithOneDict() -> PinyinDictDemoTestResult {
        let dict = TestMapDict(map: ["重庆": ["CHONG", "QING"],
                                     "长安": ["CHANG", "AN"],
                                     "四川": ["SI", "CHUAN"]])
        return assertToPinyin("testToPinyinWithOneDict",
                              input: "重庆和长安都很棒!四川",
                              sep: ",",
                              expected: "CHONG,QING,HE,CHANG,AN,DOU,HEN,BANG,!,SI,CHUAN",
                              dict: dict)
    }

    private nonisolated static func testToPinyinFirstDictWins() -> PinyinDictDemoTestResult {
        Pinyin.initialize(
            Pinyin.newConfig()
            .with(TestMapDict(map: ["重庆": ["CHONG", "QING"]]))
            .with(TestMapDict(map: ["重庆": ["NOT", "MATCH"],
                                    "长安": ["CHANG", "AN"]]))
        )
        let r = Pinyin.toPinyin("重庆长安", separator: ",")
        return check("testToPinyinFirstDictWins",
                     r == "CHONG,QING,CHANG,AN",
                     "got \(r)")
    }

    private nonisolated static func testToPinyinEmptyString() -> PinyinDictDemoTestResult {
        check("testToPinyinEmptyString",
              Pinyin.toPinyin("", separator: ",") == "",
              "got non-empty")
    }

    // MARK: - ForwardLongestSelector

    private nonisolated static func testSelectSingleHit() -> PinyinDictDemoTestResult {
        let list = [Emit(start: 0, end: 4, keyword: "abcde")]
        let r = ForwardLongestSelector().select(list)
        return check("testSelectSingleHit",
                     r?.count == 1 && r?[0].start == 0 && r?[0].end == 4,
                     "result=\(String(describing: r))")
    }

    private nonisolated static func testSelectMultiHitNoOverlap() -> PinyinDictDemoTestResult {
        let list = [Emit(start: 0, end: 5, keyword: "x"), Emit(start: 7, end: 8, keyword: "x"), Emit(start: 9, end: 10, keyword: "x")]
        let r = ForwardLongestSelector().select(list)
        let ok = r?.count == 3 && r?[0].start == 0 && r?[0].end == 5 && r?[1].start == 7 && r?[1].end == 8 && r?[2].start == 9 && r?[2].end == 10
        return check("testSelectMultiHitNoOverlap",
                     ok == true,
                     "result=\(String(describing: r))")
    }

    private nonisolated static func testSelectMultiHitWithOverlap() -> PinyinDictDemoTestResult {
        let list = [
            Emit(start: 0, end: 4, keyword: "x"), Emit(start: 0, end: 4, keyword: "x"), Emit(start: 0, end: 5, keyword: "x"),
            Emit(start: 2, end: 3, keyword: "x"), Emit(start: 2, end: 10, keyword: "x"), Emit(start: 5, end: 7, keyword: "x"),
            Emit(start: 7, end: 8, keyword: "x"), Emit(start: 8, end: 9, keyword: "x"),
        ]
        let r = ForwardLongestSelector().select(list)
        let ok = r?.count == 2 && r?[0].start == 0 && r?[0].end == 5 && r?[1].start == 7 && r?[1].end == 8
        return check("testSelectMultiHitWithOverlap",
                     ok == true,
                     "result=\(String(describing: r))")
    }

    private nonisolated static func testSelectNullReturnsNil() -> PinyinDictDemoTestResult {
        check("testSelectNullReturnsNil",
              ForwardLongestSelector().select(nil) == nil,
              "expected nil")
    }

    // MARK: - PinyinMapDict

    private nonisolated static func testWordsNonnullMapReturnsKeys() -> PinyinDictDemoTestResult {
        let words = TestMapDict(map: ["1": ["ONE"], "2": ["TWO"]]).words()
        return check("testWordsNonnullMapReturnsKeys",
                     words.count == 2 && words.contains("1") && words.contains("2"),
                     "words=\(words)")
    }

    private nonisolated static func testToPinyinNonnullMapReturnsValue() -> PinyinDictDemoTestResult {
        let r = TestMapDict(map: ["1": ["ONE"]]).toPinyin("1")
        return check("testToPinyinNonnullMapReturnsValue",
                     r == ["ONE"],
                     "\(String(describing: r))")
    }

    private nonisolated static func testToPinyinNonnullMapNoKeyReturnsNil() -> PinyinDictDemoTestResult {
        check("testToPinyinNonnullMapNoKeyReturnsNil",
              TestMapDict(map: ["1": ["ONE"]]).toPinyin("2") == nil,
              "expected nil")
    }

    // MARK: - Utils behavior

    private nonisolated static func testInitWithEmptyConfigNoDict() -> PinyinDictDemoTestResult {
        Pinyin.initialize(Pinyin.newConfig())
        return check("testInitWithEmptyConfigNoDict",
                     Pinyin.toPinyin("中", separator: "") == "ZHONG",
                     "got wrong")
    }

    private nonisolated static func testInitWithDictBuildsTrie() -> PinyinDictDemoTestResult {
        assertToPinyin("testInitWithDictBuildsTrie",
                       input: "重庆",
                       sep: ",", expected: "CHONG,QING",
                       dict: TestMapDict(map: ["重庆": ["CHONG", "QING"]]))
    }

    private nonisolated static func testKeywordsSortedOrderDeterministic() -> PinyinDictDemoTestResult {
        let dict = TestMapDict(map: ["中国": ["ZHONG", "GUO"], "重庆": ["CHONG", "QING"]])
        Pinyin.initialize(Pinyin.newConfig().with(dict))
        let r1 = Pinyin.toPinyin("中国重庆", separator: ",")
        Pinyin.initialize(Pinyin.newConfig().with(dict))
        let r2 = Pinyin.toPinyin("中国重庆", separator: ",")
        return check("testKeywordsSortedOrderDeterministic",
                     r1 == r2,
                     "\(r1) vs \(r2)")
    }
}
