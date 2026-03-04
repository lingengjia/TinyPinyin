//
//  Trie.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/10.
//

import Foundation

public struct Emit: Hashable {
    public let start: Int
    public let end: Int       // 包含 end，下标是 [start, end]
    public let keyword: String

    public var size: Int {
        return end - start + 1
    }
}

// MARK: - Trie

public final class Trie {

    // 内部节点
    private final class Node {
        var children: [Character: Node] = [:]
        weak var failure: Node?
        var emits: [String] = []

        func addChild(_ c: Character) -> Node {
            if let n = children[c] { return n }
            let n = Node()
            children[c] = n
            return n
        }

        func getChild(_ c: Character) -> Node? {
            return children[c]
        }

        func addEmit(_ keyword: String) {
            emits.append(keyword)
        }
    }

    private let root = Node()

    // 只允许通过 Builder 构造
    fileprivate init() {}

    // 核心：解析文本，返回所有 Emit（和 Java 的 parseText 等价）
    public func parseText(_ text: String) -> [Emit] {
        var emits: [Emit] = []
        var currentNode: Node = root
        let chars = Array(text)

        for (i, ch) in chars.enumerated() {
            currentNode = getNextState(from: currentNode, with: ch)
            if !currentNode.emits.isEmpty {
                for keyword in currentNode.emits {
                    let length = keyword.count
                    let emit = Emit(start: i - length + 1, end: i, keyword: keyword)
                    emits.append(emit)
                }
            }
        }

        return emits
    }

    // Aho-Corasick：沿 failure 链回溯，直到找到下一个状态
    private func getNextState(from node: Node, with ch: Character) -> Node {
        var current: Node? = node
        while current != nil && current?.getChild(ch) == nil {
            if current === root {
                current = nil
                break
            }
            current = current?.failure
        }
        return current?.getChild(ch) ?? root
    }

    // MARK: - Builder（等价 Trie.TrieBuilder）

    public final class Builder {
        private let trie = Trie()

        public init() {}

        public func addKeyword(_ keyword: String) -> Builder {
            guard !keyword.isEmpty else { return self }
            var current = trie.root
            for ch in keyword {
                current = current.addChild(ch)
            }
            current.addEmit(keyword)
            return self
        }

        public func build() -> Trie {
            buildFailureLinks()
            return trie
        }

        private func buildFailureLinks() {
            var queue: [Node] = []

            // root 子节点的 failure 都指向 root
            for child in trie.root.children.values {
                child.failure = trie.root
                queue.append(child)
            }

            while !queue.isEmpty {
                let current = queue.removeFirst()

                for (ch, child) in current.children {
                    queue.append(child)

                    var failureNode = current.failure
                    while failureNode != nil && failureNode?.getChild(ch) == nil {
                        if failureNode === trie.root {
                            failureNode = nil
                            break
                        }
                        failureNode = failureNode?.failure
                    }

                    child.failure = failureNode?.getChild(ch) ?? trie.root
                    // failure 链上的 emits 也要合并过来
                    if let f = child.failure {
                        child.emits.append(contentsOf: f.emits)
                    }
                }
            }
        }
    }
}
