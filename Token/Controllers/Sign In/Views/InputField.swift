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

import UIKit
import SweetUIKit

class InputField: UIView {

    static let height: CGFloat = 45

    enum FieldType {
        case username
        case password
    }

    var type: FieldType!

    lazy var textField: UITextField = {
        let view = UITextField(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.darkTextColor
        view.delegate = self

        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.isUserInteractionEnabled = false
        view.font = Theme.regular(size: 16)
        view.text = self.type == .username ? "Username" : "Password"
        view.textColor = Theme.greyTextColor
        view.textAlignment = .left

        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        view.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)

        return view
    }()

    lazy var topSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var shortBottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var bottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    fileprivate lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    convenience init(type: FieldType) {
        self.init(withAutoLayout: true)
        self.type = type
        self.backgroundColor = .white

        self.addSubview(self.topSeparatorView)
        self.addSubview(self.shortBottomSeparatorView)
        self.addSubview(self.bottomSeparatorView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.textField)

        NSLayoutConstraint.activate([
            self.topSeparatorView.topAnchor.constraint(equalTo: self.topAnchor),
            self.topSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.topSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.topSeparatorView.heightAnchor.constraint(equalToConstant: Theme.borderHeight),

            self.shortBottomSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.shortBottomSeparatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.shortBottomSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.shortBottomSeparatorView.heightAnchor.constraint(equalToConstant: Theme.borderHeight),

            self.bottomSeparatorView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.bottomSeparatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.bottomSeparatorView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.bottomSeparatorView.heightAnchor.constraint(equalToConstant: Theme.borderHeight),

            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.textField.topAnchor.constraint(equalTo: self.topAnchor),
            self.textField.leftAnchor.constraint(equalTo: self.titleLabel.rightAnchor, constant: 20),
            self.textField.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.textField.rightAnchor.constraint(equalTo: self.rightAnchor),
        ])

        if self.type == .username {
            self.bottomSeparatorView.isHidden = true
        } else {
            self.topSeparatorView.isHidden = true
            self.shortBottomSeparatorView.isHidden = true
        }

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))
    }

    func tap(_: UITapGestureRecognizer) {
        self.textField.becomeFirstResponder()
    }
}

extension InputField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_: UITextField) {
        self.feedbackGenerator.impactOccurred()
    }
}
