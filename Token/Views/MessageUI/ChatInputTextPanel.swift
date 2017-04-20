// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import NoChat
import UIKit
import HPGrowingTextView
import SweetUIKit

protocol ChatInputTextPanelDelegate: NOCChatInputPanelDelegate {
    func inputTextPanel(_ inputTextPanel: ChatInputTextPanel, requestSendText text: String)
    func inputTextPanelrequestSendAttachment(_ inputTextPanel: ChatInputTextPanel)
    func inputTextPanelDidChangeHeight(_ height: CGFloat)
}

class ChatInputTextPanel: NOCChatInputPanel {

    static let defaultHeight: CGFloat = 51

    fileprivate let inputContainerInsets = UIEdgeInsets(top: 8, left: 41, bottom: 7, right: 0)
    fileprivate let maximumInputContainerHeight: CGFloat = 175
    fileprivate var inputContainerHeight: CGFloat = ChatInputTextPanel.defaultHeight {
        didSet {
            if self.inputContainerHeight != oldValue {
                if let delegate = self.delegate as? ChatInputTextPanelDelegate {
                    delegate.inputTextPanelDidChangeHeight(self.inputContainerHeight)
                }
            }
        }
    }

    fileprivate func inputContainerHeight(for textViewHeight: CGFloat) -> CGFloat {
        return min(self.maximumInputContainerHeight, max(ChatInputTextPanel.defaultHeight, textViewHeight + self.inputContainerInsets.top + self.inputContainerInsets.bottom))
    }

    lazy var inputContainer: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.inputFieldBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight

        return view
    }()

    lazy var inputField: HPGrowingTextView = {
        let view = HPGrowingTextView(withAutoLayout: true)
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = (ChatInputTextPanel.defaultHeight - (self.inputContainerInsets.top + self.inputContainerInsets.bottom)) / 2
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight
        view.delegate = self
        view.font = UIFont.systemFont(ofSize: 16)
        view.internalTextView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        view.internalTextView.scrollIndicatorInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 5)

        return view
    }()

    fileprivate lazy var attachButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "TGAttachButton").withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = Theme.tintColor
        view.contentMode = .center
        view.addTarget(self, action: #selector(attach(_:)), for: .touchUpInside)

        return view
    }()

    fileprivate lazy var sendButton: ActionButton = {
        let view = ActionButton(margin: 0)
        view.title = "Send"
        view.style = .plain
        view.titleLabel.font = Theme.semibold(size: 16)
        view.heightConstraint.constant = ChatInputTextPanel.defaultHeight
        view.isEnabled = false
        view.addTarget(self, action: #selector(send(_:)), for: .touchUpInside)

        return view
    }()

    public var text: String? {
        get {
            return inputField.text
        } set {
            self.inputField.text = newValue ?? ""
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.addSubview(self.inputContainer)
        self.addSubview(self.attachButton)
        self.addSubview(self.inputField)
        self.addSubview(self.sendButton)

        NSLayoutConstraint.activate([
            self.attachButton.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.attachButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.attachButton.rightAnchor.constraint(equalTo: self.inputField.leftAnchor),
            self.attachButton.widthAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight),
            self.attachButton.heightAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight),

            self.inputContainer.topAnchor.constraint(equalTo: self.topAnchor),
            self.inputContainer.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -1),
            self.inputContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.inputContainer.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 1),

            self.inputField.topAnchor.constraint(equalTo: self.topAnchor, constant: self.inputContainerInsets.top),
            self.inputField.leftAnchor.constraint(equalTo: self.attachButton.rightAnchor),
            self.inputField.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.inputContainerInsets.bottom),

            self.sendButton.leftAnchor.constraint(equalTo: self.inputField.rightAnchor),
            self.sendButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.sendButton.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.sendButton.widthAnchor.constraint(equalToConstant: 70),
        ])
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        if self.point(inside: point, with: event) {

            for subview in self.subviews.reversed() {
                let point = subview.convert(point, from: self)

                if let hitTestView = subview.hitTest(point, with: event) {
                    return hitTestView
                }
            }

            return nil
        }

        return nil
    }

    func attach(_: ActionButton) {
        if let delegate = self.delegate as? ChatInputTextPanelDelegate {
            delegate.inputTextPanelrequestSendAttachment(self)
        }
    }

    func send(_: ActionButton) {
        // Resign and become first responder to accept auto-correct suggestions
        self.inputField.internalTextView.resignFirstResponder()
        self.inputField.internalTextView.becomeFirstResponder()
        
        guard let text = self.inputField.text, text.characters.count > 0 else { return }

        let string = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.characters.count > 0 {
            if let delegate = self.delegate as? ChatInputTextPanelDelegate {
                delegate.inputTextPanel(self, requestSendText: string)
            }
        }

        self.text = nil
        self.sendButton.isEnabled = false
    }
}

extension ChatInputTextPanel: HPGrowingTextViewDelegate {

    func growingTextView(_ textView: HPGrowingTextView!, willChangeHeight _: Float) {
        inputContainerHeight = inputContainerHeight(for: textView.frame.height)
    }

    func growingTextViewDidChange(_ textView: HPGrowingTextView!) {
        sendButton.isEnabled = inputField.internalTextView.hasText
        inputContainerHeight = inputContainerHeight(for: textView.frame.height)
    }
}
