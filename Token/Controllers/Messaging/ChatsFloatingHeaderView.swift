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

protocol ChatsFloatingHeaderViewDelegate: class {
    func messagesFloatingView(_ messagesFloatingView: ChatsFloatingHeaderView, didPressRequestButton button: UIButton)
    func messagesFloatingView(_ messagesFloatingView: ChatsFloatingHeaderView, didPressPayButton button: UIButton)
}

class ChatsFloatingHeaderView: UIView {
    weak var delegate: ChatsFloatingHeaderViewDelegate?

    static let height = CGFloat(48)

    lazy var balanceLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.darkTextColor
        label.font = Theme.regular(size: 16)

        return label
    }()

    static func button() -> UIButton {
        let button = UIButton(withAutoLayout: true)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.titleLabel?.font = Theme.semibold(size: 13)

        return button
    }

    lazy var requestButton: UIButton = {
        let button = ChatsFloatingHeaderView.button()
        button.setTitle("Request", for: .normal)
        button.addTarget(self, action: #selector(request(button:)), for: .touchUpInside)

        return button
    }()

    lazy var payButton: UIButton = {
        let button = ChatsFloatingHeaderView.button()
        button.setTitle("Pay", for: .normal)
        button.addTarget(self, action: #selector(pay(button:)), for: .touchUpInside)

        return button
    }()

    var balance: NSDecimalNumber? {
        didSet {
            if let balance = self.balance {
                self.balanceLabel.attributedText = EthereumConverter.balanceAttributedString(forWei: balance)
            } else {
                self.balanceLabel.attributedText = nil
            }
        }
    }

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = Theme.viewBackgroundColor
        self.addSubview(self.balanceLabel)
        self.addSubview(self.requestButton)
        self.addSubview(self.payButton)
        self.addSubview(self.separatorView)

        let margin = CGFloat(10)
        self.balanceLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.balanceLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.balanceLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin).isActive = true

        let buttonWidth = CGFloat(70)
        self.requestButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.requestButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.requestButton.leftAnchor.constraint(equalTo: self.balanceLabel.rightAnchor).isActive = true
        self.requestButton.rightAnchor.constraint(equalTo: self.payButton.leftAnchor).isActive = true
        self.requestButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true

        self.payButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.payButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.payButton.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.payButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true

        self.separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        self.separatorView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func request(button: UIButton) {
        self.delegate?.messagesFloatingView(self, didPressRequestButton: button)
    }

    func pay(button: UIButton) {
        self.delegate?.messagesFloatingView(self, didPressPayButton: button)
    }
}
