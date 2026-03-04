//
//  BenchmarkUtils.swift
//  TinyPinyinDemo
//
//  Created by gengjia lin on 2026/3/4.
//

import Foundation

// 与 Android TinyPinyin lib/src/jmh/.../BenchmarkUtils 对齐：提供性能测试用样本与随机生成。
struct BenchmarkUtils {

    /// 内置样本长文本（Android 从 sample.txt 读取，此处写死一段足够长的中文）
    nonisolated private static let sampleStr: String = {
        let parts = [
            "中国重庆和长安都是历史名城，四川成都也很有名。",
            "北京上海广州深圳杭州南京武汉西安成都重庆天津苏州郑州长沙青岛济南哈尔滨沈阳大连厦门宁波无锡合肥佛山东莞福州石家庄南昌贵阳南宁兰州海口银川西宁乌鲁木齐拉萨呼和浩特",
            "汉字转拼音是常见需求，TinyPinyin 提供轻量高效的实现。",
            "多音字需要词典支持，例如重庆读作 CHONG QING，长安读作 CHANG AN。",
            "软件开发中经常用到拼音排序、拼音首字母、拼音搜索等功能。",
            "春夏秋冬四季轮回，东西南北方位明确，日月星辰宇宙浩瀚。",
            "读书写字学文化，科技教育兴国家。",
        ]
        return String(parts.flatMap { $0 + $0 + $0 }) // 重复以拉长，便于截取 1000 字
    }()

    /// 生成指定长度的随机子串（从样本中随机起点截取，与 Android genRandomString 行为一致）
    nonisolated static func genRandomString(length: Int) -> String {
        let full = fullSampleStr()
        let maxStart = full.count - length
        guard maxStart > 0 else { return String(full.prefix(length)) }
        let start = Int.random(in: 0...maxStart)
        let startIdx = full.index(full.startIndex, offsetBy: start)
        let endIdx = full.index(startIdx, offsetBy: length)
        return String(full[startIdx..<endIdx])
    }

    /// 随机生成一个字符（用于 CharToPinyin / IsChinese 类 benchmark，与 Android genRandomChar 对齐）
    nonisolated static func genRandomChar() -> Character {
        let scalar = Unicode.Scalar(Int.random(in: 0x4E00...0x9FFF))!
        return Character(scalar)
    }

    nonisolated private static func fullSampleStr() -> String {
        return sampleStr
    }
}
