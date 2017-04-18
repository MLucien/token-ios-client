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
import Formulaic

/// Display profile items for editing inside ProfileEditController
class ProfileItemCell: UITableViewCell {

    var formItem: FormItem? {
        didSet {
            self.itemLabel.text = self.formItem?.title
            self.itemTextField.text = self.formItem?.value as? String
        }
    }

    lazy var itemLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)

        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        return view
    }()

    lazy var itemTextField: UITextField = {
        let view = UITextField(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.regular(size: 15)
        view.textAlignment = .right

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.itemLabel)
        self.contentView.addSubview(self.itemTextField)
        self.contentView.addSubview(self.separatorView)

        let margin: CGFloat = 22.0

        self.itemLabel.set(height: 44)
        self.itemLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.itemLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true
        self.itemLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true

        self.itemTextField.set(height: 44)
        self.itemTextField.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.itemTextField.leftAnchor.constraint(equalTo: self.itemLabel.rightAnchor, constant: margin).isActive = true
        self.itemTextField.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.itemTextField.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin).isActive = true

        self.separatorView.set(height: Theme.borderHeight)
        self.separatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.separatorView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(ProfileItemCell.textFieldDidChange), name: .UITextFieldTextDidChange, object: self.itemTextField)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        self.formItem = nil
    }
}

extension ProfileItemCell: UITextFieldDelegate {

    func textFieldDidChange() {
        self.formItem?.updateValue(to: self.itemTextField.text, userInitiated: true)
    }
}
