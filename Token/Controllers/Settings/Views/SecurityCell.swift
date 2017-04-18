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

class SecurityCell: BaseCell {

    lazy var checkbox: Checkbox = {
        let view = Checkbox(withAutoLayout: true)
        view.checked = false

        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)
        view.numberOfLines = 0
        view.text = ""

        return view
    }()

    var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let margin = CGVector(dx: 46, dy: 16)

        self.contentView.addSubview(self.checkbox)
        self.contentView.addSubview(self.titleLabel)

        NSLayoutConstraint.activate([
            self.checkbox.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: (margin.dx / 2) - (Checkbox.size / 2)),
            self.checkbox.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
        ])

        self.titleLabel.text = "Store backup phrase"
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin.dy),
            self.titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin.dx),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin.dy),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -40),
        ])
    }
}
