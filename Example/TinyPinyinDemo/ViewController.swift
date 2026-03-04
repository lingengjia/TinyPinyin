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

        inputTextField.text = "你好世界"

        view.addSubview(inputTextField)
        view.addSubview(separatorTextField)
        view.addSubview(convertButton)
        view.addSubview(resultLabel)

        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)

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

            resultLabel.topAnchor.constraint(equalTo: convertButton.bottomAnchor, constant: 24),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    @objc private func convertTapped() {
        let text = inputTextField.text ?? ""
        let sep = separatorTextField.text?.isEmpty == true ? " " : (separatorTextField.text ?? " ")
        let result = Pinyin.toPinyin(text, separator: sep)
        resultLabel.text = result.isEmpty ? "(空)" : result
        resultLabel.textColor = .label
        view.endEditing(true)
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

