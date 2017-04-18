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

class HomeItemCell: UICollectionViewCell {
    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var displayNameLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.medium(size: 14)
        label.textColor = Theme.darkTextColor
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.displayNameLabel)

        self.avatarImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.avatarImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 44).isActive = true
        self.avatarImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 44).isActive = true

        self.displayNameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor).isActive = true
        self.displayNameLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.displayNameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.displayNameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }

    var app: TokenContact? {
        didSet {
            guard let app = self.app else {
                self.displayNameLabel.text = nil
                self.avatarImageView.image = nil

                return
            }

            self.displayNameLabel.text = app.displayName

            if let image = self.app?.avatar {
                self.avatarImageView.image = image
            } else if let app = self.app {
                AppsAPIClient.shared.downloadImage(for: app) { image in
                    self.avatarImageView.image = image
                }
            }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
