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

class SearchResultCell: UITableViewCell {
    var app: TokenContact? {
        didSet {
            if let app = self.app {
                self.usernameLabel.text = app.category
                self.nameLabel.text = app.displayName

                if let image = app.avatar {
                    self.avatarImageView.image = image
                } else {
                    AppsAPIClient.shared.downloadImage(for: app) { image in
                        self.avatarImageView.image = image
                    }
                }
            } else {
                self.usernameLabel.text = nil
                self.nameLabel.text = nil
            }
        }
    }

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        view.textColor = Theme.greyTextColor
        view.font = Theme.regular(size: 14)

        return view
    }()

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.separatorView)

        let margin: CGFloat = 16.0
        let interLabelMargin: CGFloat = 6.0
        let imageSize: CGFloat = 44.0
        let height: CGFloat = 24.0

        self.avatarImageView.clipsToBounds = true
        self.avatarImageView.cornerRadius = imageSize / 2

        self.avatarImageView.set(height: imageSize)
        self.avatarImageView.set(width: imageSize)
        self.avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true

        self.nameLabel.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.nameLabel.topAnchor.constraint(greaterThanOrEqualTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true
        self.nameLabel.rightAnchor.constraint(greaterThanOrEqualTo: self.contentView.rightAnchor, constant: -margin).isActive = true

        self.usernameLabel.heightAnchor.constraint(equalToConstant: height).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: interLabelMargin).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -margin).isActive = true
        self.usernameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin).isActive = true

        self.separatorView.set(height: Theme.borderHeight)
        self.separatorView.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }
}
