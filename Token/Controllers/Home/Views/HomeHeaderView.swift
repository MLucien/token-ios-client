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

class HomeContainerView: UIView {
    lazy var balanceTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 14)
        label.textColor = Theme.greyTextColor
        label.text = "Balance"

        return label
    }()

    lazy var balanceFiatLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 20)
        label.textAlignment = .left
        label.textColor = Theme.darkTextColor

        return label
    }()

    lazy var balanceEtherLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 16)
        label.textAlignment = .right
        label.textColor = Theme.greyTextColor

        return label
    }()

    lazy var payButton: HomeButton = {
        let view = HomeButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "pay-button"))
        view.setSubtitle("Pay")
        view.addTarget(self, action: #selector(pay), for: .touchUpInside)

        return view
    }()

    lazy var requestButton: HomeButton = {
        let view = HomeButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "request-button"))
        view.setSubtitle("Request")
        view.addTarget(self, action: #selector(request), for: .touchUpInside)

        return view
    }()

    lazy var addFundsButton: HomeButton = {
        let view = HomeButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "add-money-button"))
        view.setSubtitle("Add Funds")
        view.addTarget(self, action: #selector(addFunds), for: .touchUpInside)

        return view
    }()

    lazy var scanButton: HomeButton = {
        let view = HomeButton(withAutoLayout: true)
        view.setImage(#imageLiteral(resourceName: "scan-qr-button"))
        view.setSubtitle("Scan QR")
        view.addTarget(self, action: #selector(scan), for: .touchUpInside)

        return view
    }()

    lazy var actionStackView: UIStackView = {
        let view = UIStackView(withAutoLayout: true)
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = 15

        view.addArrangedSubview(self.payButton)
        view.addArrangedSubview(self.requestButton)
        view.addArrangedSubview(self.addFundsButton)
        view.addArrangedSubview(self.scanButton)

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = Theme.viewBackgroundColor

        //        let separator = UIView(withAutoLayout: true)
        //        separator.backgroundColor = Theme.borderColor
        //        separator.set(height: Theme.borderHeight)
        //
        //        self.addSubview(separator)
        self.addSubview(self.balanceTitleLabel)
        self.addSubview(self.balanceFiatLabel)
        self.addSubview(self.balanceEtherLabel)

        //        self.addSubview(self.actionStackView)

        let verticalMargin: CGFloat = 20
        let horizontalMargin: CGFloat = 20

        self.balanceTitleLabel.set(height: 20)
        self.balanceTitleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: verticalMargin).isActive = true
        self.balanceTitleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: horizontalMargin).isActive = true
        self.balanceTitleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -horizontalMargin).isActive = true

        self.balanceFiatLabel.widthAnchor.constraint(equalTo: self.balanceEtherLabel.widthAnchor).isActive = true
        self.balanceFiatLabel.topAnchor.constraint(equalTo: self.balanceTitleLabel.topAnchor, constant: verticalMargin).isActive = true
        self.balanceFiatLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: horizontalMargin).isActive = true
        self.balanceFiatLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -verticalMargin).isActive = true

        self.balanceEtherLabel.topAnchor.constraint(equalTo: self.balanceTitleLabel.topAnchor, constant: verticalMargin).isActive = true
        self.balanceEtherLabel.leftAnchor.constraint(equalTo: self.balanceFiatLabel.rightAnchor).isActive = true
        self.balanceEtherLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -horizontalMargin).isActive = true
        self.balanceEtherLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -verticalMargin).isActive = true

        //        separator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        //        separator.leftAnchor.constraint(equalTo: self.leftAnchor, constant: horizontalMargin).isActive = true
        //        separator.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -horizontalMargin).isActive = true

        //        self.actionStackView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: verticalMargin).isActive = true
        //        self.actionStackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: horizontalMargin).isActive = true
        //        self.actionStackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -horizontalMargin).isActive = true
        //        self.actionStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -verticalMargin).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var balance: NSDecimalNumber? {
        didSet {
            if let balance = self.balance {
                self.balanceFiatLabel.text = EthereumConverter.fiatValueStringWithCode(forWei: balance)
                self.balanceEtherLabel.text = EthereumConverter.ethereumValueString(forWei: balance)
            } else {
                self.balanceFiatLabel.text = nil
                self.balanceEtherLabel.text = nil
            }
        }
    }

    func pay() {
        print("Tapped pay button")
    }

    func request() {
        print("Tapped request button")
    }

    func addFunds() {
        print("Tapped add funds button")
    }

    func scan() {
        print("Tapped scan button")
    }
}
