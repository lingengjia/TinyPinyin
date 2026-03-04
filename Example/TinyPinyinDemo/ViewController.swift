//
//  ViewController.swift
//  TinyPinyinDemo
//
//  Created by gengjia lin on 2026/3/4.
//

import UIKit
import TinyPinyin

class ViewController: UIViewController {

    private let inputTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "输入中文或混合文本"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let separatorTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "拼音分隔符"
        tf.borderStyle = .roundedRect
        tf.text = " "
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let convertButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("转拼音", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let testButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("运行测试", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let benchmarkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("运行性能测试", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "点击「转拼音」按钮转换"
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TinyPinyin Demo"
        view.backgroundColor = .systemBackground
        
        let dict = TestMapDict(map:["重庆": ["CHONG", "QING"], "长安": ["CHANG", "AN"], "四川": ["SI", "CHUAN"]])
        Pinyin.initialize(Pinyin.newConfig().with(dict))
        
        inputTextField.text = "你好世界"

        view.addSubview(inputTextField)
        view.addSubview(separatorTextField)
        view.addSubview(convertButton)
        view.addSubview(testButton)
        view.addSubview(benchmarkButton)
        view.addSubview(resultLabel)

        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        testButton.addTarget(self, action: #selector(runTestsTapped), for: .touchUpInside)
        benchmarkButton.addTarget(self, action: #selector(runBenchmarkTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            inputTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            inputTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputTextField.heightAnchor.constraint(equalToConstant: 44),

            separatorTextField.topAnchor.constraint(equalTo: inputTextField.bottomAnchor, constant: 12),
            separatorTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            separatorTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            separatorTextField.heightAnchor.constraint(equalToConstant: 44),

            convertButton.topAnchor.constraint(equalTo: separatorTextField.bottomAnchor, constant: 20),
            convertButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            testButton.topAnchor.constraint(equalTo: convertButton.bottomAnchor, constant: 12),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            benchmarkButton.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 12),
            benchmarkButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            resultLabel.topAnchor.constraint(equalTo: benchmarkButton.bottomAnchor, constant: 24),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        
        demo()
    }

    @objc private func convertTapped() {
        let text = inputTextField.text ?? ""
        let sep = separatorTextField.text?.isEmpty == true ? " " : (separatorTextField.text ?? " ")
        let result = Pinyin.toPinyin(text, separator: sep)
        resultLabel.text = result.isEmpty ? "(空)" : result
        resultLabel.textColor = .label
        view.endEditing(true)
    }

    @objc private func runTestsTapped() {
        let (passed, failed, results) = PinyinDictDemoTests.runAll()
        var message = "通过 \(passed) / 失败 \(failed)"
        if failed > 0 {
            let failedList = results.filter { !$0.passed }
            message += "\n\n失败用例:\n" + failedList.map { "• \($0.name): \($0.message)" }.joined(separator: "\n")
        } else {
            message += "\n\n全部通过 ✓"
        }
        resultLabel.text = message
        resultLabel.textColor = failed > 0 ? .systemRed : .label
        let alert = UIAlertController(title: "测试结果", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    @objc private func runBenchmarkTapped() {
        resultLabel.text = "性能测试中…"
        resultLabel.textColor = .secondaryLabel
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let results = PinyinBenchmark.runAll()
            let lines = results.map { "\($0.name): \($0.description)" }
            let message = "TinyPinyin 性能\n\n" + lines.joined(separator: "\n")
            print("========== TinyPinyin 性能测试 ==========")
            for r in results {
                print("  \(r.name): \(r.description)")
            }
            print("==========================================")
            DispatchQueue.main.async {
                self?.resultLabel.text = message
                self?.resultLabel.textColor = .label
                let alert = UIAlertController(title: "性能测试", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    private func demo() {
        print("=== TinyPinyin Demo ===\n")

        let text = "你好世界"
        let pinyin = Pinyin.toPinyin(text, separator: " ")
        print("toPinyin(\"\(text)\", separator: \" \")")
        print("  -> \"\(pinyin)\"\n")

        let chars: [Character] = ["中", "文", "A", "1"]
        print("单字转拼音:")
        for c in chars {
            let py = Pinyin.toPinyin(c)
            let isChinese = Pinyin.isChinese(c)
            print("  '\(c)' -> \"\(py)\" (isChinese: \(isChinese))")
        }
        
        print("\nDone.")
    }
}

