//
//  PinyinBenchmark.swift
//  TinyPinyinDemo
//
//  Created by gengjia lin on 2026/3/4.
//

// 与 Android TinyPinyin jmh 性能测试对齐：Init、CharToPinyin、IsChinese、StringToPinyin。
import Foundation
import TinyPinyin

struct PinyinBenchmarkResult {
    let name: String
    let value: Double
    let unit: String  // "ops/s" or "ms/op"
    let description: String
}

struct PinyinBenchmark {

    /// 小词典（对齐 Android CnCityDict 量级）
    nonisolated private static var smallDict: TestMapDict {
        TestMapDict(map: [
            "重庆": ["CHONG", "QING"],
            "长安": ["CHANG", "AN"],
            "四川": ["SI", "CHUAN"],
            "北京": ["BEI", "JING"],
            "上海": ["SHANG", "HAI"],
            "广州": ["GUANG", "ZHOU"],
            "深圳": ["SHEN", "ZHEN"],
            "杭州": ["HANG", "ZHOU"],
            "南京": ["NAN", "JING"],
            "武汉": ["WU", "HAN"],
            "西安": ["XI", "AN"],
            "成都": ["CHENG", "DU"],
            "天津": ["TIAN", "JIN"],
            "苏州": ["SU", "ZHOU"],
            "郑州": ["ZHENG", "ZHOU"],
        ])
    }

    /// 大词典（对齐 Android FullDiffDict 量级，用于 Init 与 StringToPinyin 压测）
    nonisolated private static var largeDict: TestMapDict {
        var map: [String: [String]] = [:]
        let words = ["重", "长", "中", "和", "大", "小", "多", "少", "上", "下", "东", "西", "南", "北", "春", "夏", "秋", "冬"]
        let pinyins = ["ZHONG", "CHANG", "HE", "DA", "XIAO", "DUO", "SHAO", "SHANG", "XIA", "DONG", "XI", "NAN", "BEI", "CHUN", "XIA", "QIU", "DONG"]
        for i in 0..<min(words.count, pinyins.count) {
            for j in 0..<20 {
                let key = words[i] + "\(j)"
                map[key] = [pinyins[i]]
            }
        }
        // 再加一批双字词
        for (k, v) in smallDict.map {
            map[k] = v
        }
        return TestMapDict(map: map)
    }

    /// 执行单次 benchmark：先预热，再计时跑 iterations 次，返回 (总秒数, 迭代次数)
    nonisolated private static func measure(iterations: Int,
                                            warmup: Int = 100,
                                            block: () -> Void) -> (seconds: Double, count: Int) {
        for _ in 0..<warmup { block() }
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations { block() }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        return (elapsed, iterations)
    }

    /// 运行全部性能项，返回结果列表（与 Android JMH 对应）
    nonisolated static func runAll() -> [PinyinBenchmarkResult] {
        var results: [PinyinBenchmarkResult] = []

        // 1) Init with small dict（对应 PinyinDictBenchmark1.TinyPinyin_Init_With_Small_Dict）
        do {
            let (sec, n) = measure(iterations: 200, warmup: 20) {
                Pinyin.initialize(nil)
                Pinyin.initialize(Pinyin.newConfig().with(smallDict))
            }
            let opsPerSec = n > 0 && sec > 0 ? Double(n) / sec : 0
            results.append(PinyinBenchmarkResult(
                name: "Init_With_Small_Dict",
                value: opsPerSec,
                unit: "ops/s",
                description: String(format: "%.0f ops/s", opsPerSec)
            ))
        }

        // 2) Init with large dict（对应 PinyinDictBenchmark1.TinyPinyin_Init_With_Large_Dict）
        do {
            let dict = largeDict
            let (sec, n) = measure(iterations: 50, warmup: 5) {
                Pinyin.initialize(nil)
                Pinyin.initialize(Pinyin.newConfig().with(dict))
            }
            let opsPerSec = n > 0 && sec > 0 ? Double(n) / sec : 0
            results.append(PinyinBenchmarkResult(
                name: "Init_With_Large_Dict",
                value: opsPerSec,
                unit: "ops/s",
                description: String(format: "%.0f ops/s", opsPerSec)
            ))
        }

        Pinyin.initialize(nil)

        // 3) IsChinese（对应 PinyinSampleBenchmark.TinyPinyin_IsChinese）
        do {
            let (sec, n) = measure(iterations: 50_000, warmup: 500) {
                _ = Pinyin.isChinese(BenchmarkUtils.genRandomChar())
            }
            let opsPerSec = n > 0 && sec > 0 ? Double(n) / sec : 0
            results.append(PinyinBenchmarkResult(
                name: "IsChinese",
                value: opsPerSec,
                unit: "ops/s",
                description: String(format: "%.0f ops/s", opsPerSec)
            ))
        }

        // 4) CharToPinyin（对应 PinyinSampleBenchmark.TinyPinyin_CharToPinyin）
        do {
            let (sec, n) = measure(iterations: 50_000, warmup: 500) {
                _ = Pinyin.toPinyin(BenchmarkUtils.genRandomChar())
            }
            let opsPerSec = n > 0 && sec > 0 ? Double(n) / sec : 0
            results.append(PinyinBenchmarkResult(
                name: "CharToPinyin",
                value: opsPerSec,
                unit: "ops/s",
                description: String(format: "%.0f ops/s", opsPerSec)
            ))
        }

        // 5) StringToPinyin with large dict（对应 PinyinDictBenchmark2，1000 字随机串）
        do {
            Pinyin.initialize(Pinyin.newConfig().with(largeDict))
            let inputStr = BenchmarkUtils.genRandomString(length: 1000)
            let (sec, n) = measure(iterations: 200, warmup: 20) {
                _ = Pinyin.toPinyin(inputStr, separator: ",")
            }
            let msPerOp = n > 0 && sec > 0 ? (sec * 1000.0) / Double(n) : 0
            results.append(PinyinBenchmarkResult(
                name: "StringToPinyin_1000chars_LargeDict",
                value: msPerOp,
                unit: "ms/op",
                description: String(format: "%.2f ms/op", msPerOp)
            ))
        }

        Pinyin.initialize(nil)
        return results
    }
}
