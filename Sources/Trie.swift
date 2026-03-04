//
//  Trie.swift
//  TinyPinyin
//
//  Created by gengjia lin on 2026/2/10.
//

import Foundation

public struct Emit: Hashable {
    public let start: Int
    // Containing "end", with subscripts [start, end]
    public let end: Int
    public let keyword: String

    public var size: Int {
        return end - start + 1
    }
}

// MARK: - Trie

public final class Trie {

    private final class Node {
        var children: [Character: Node] = [:]
        weak var failure: Node?
        var emits: [String] = []

        func addChild(_ char: Character) -> Node {
            if let node = children[char] {
                return node
            }
            let node = Node()
            children[char] = node
            return node
        }

        func getChild(_ char: Character) -> Node? {
            return children[char]
        }

        func addEmit(_ keyword: String) {
            emits.append(keyword)
        }
    }

    private let root = Node()

    fileprivate init() {}

    // Parse the text and return all Emit (equivalent to Java's parseText)
    public func parseText(_ text: String) -> [Emit] {
        var emits: [Emit] = []
        var currentNode: Node = root
        let chars = Array(text)

        for (i, char) in chars.enumerated() {
            currentNode = getNextState(from: currentNode, with: char)
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

    // Trace back along the failure chain until the next state is found
    private func getNextState(from node: Node, with char: Character) -> Node {
        var current: Node? = node
        while current != nil && current?.getChild(char) == nil {
            if current === root {
                current = nil
                break
            }
            current = current?.failure
        }
        return current?.getChild(char) ?? root
    }

    // MARK: - Builder (equivalent to Trie.TrieBuilder)

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

            // All failures of the root child node point to root
            for child in trie.root.children.values {
                child.failure = trie.root
                queue.append(child)
            }

            while !queue.isEmpty {
                let current = queue.removeFirst()
                for (ch, child) in current.children {
                    queue.append(child)
                    var failureNode = current.failure
                    while failureNode != nil,
                          failureNode?.getChild(ch) == nil {
                        if failureNode === trie.root {
                            failureNode = nil
                            break
                        }
                        failureNode = failureNode?.failure
                    }
                    child.failure = failureNode?.getChild(ch) ?? trie.root
                    // The emits on the failure chain should also be merged
                    if let f = child.failure {
                        child.emits.append(contentsOf: f.emits)
                    }
                }
            }
        }
     }
}
