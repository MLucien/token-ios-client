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

class AppCell: UICollectionViewCell {
    static let avatarSize = CGFloat(89)

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.medium(size: 15)
        label.textColor = Theme.darkTextColor
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    lazy var categoryLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.medium(size: 14)
        label.textColor = Theme.lightGreyTextColor
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    lazy var ratingView: RatingView = {
        let view = RatingView(numberOfStars: 5)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    var app: TokenContact? {
        didSet {
            guard let app = self.app else {
                self.nameLabel.text = nil
                self.avatarImageView.image = nil

                return
            }

            NotificationCenter.default.addObserver(self, selector: #selector(avatarDidUpdate), name: .TokenContactDidUpdateAvatarNotification, object: app)

            self.nameLabel.text = app.name
            self.categoryLabel.text = app.category

            if let image = app.avatar {
                self.avatarImageView.image = image
            }

            RatingsClient.shared.scores(for: app.address) { ratingScore in
                self.ratingView.set(rating: Float(ratingScore.score))
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.categoryLabel)
        self.contentView.addSubview(self.ratingView)

        self.avatarImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.avatarImageView.heightAnchor.constraint(equalToConstant: AppCell.avatarSize).isActive = true
        self.avatarImageView.widthAnchor.constraint(equalToConstant: AppCell.avatarSize).isActive = true

        self.nameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: 5).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        self.categoryLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: 5).isActive = true
        self.categoryLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
        self.categoryLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

        self.ratingView.topAnchor.constraint(equalTo: self.categoryLabel.bottomAnchor, constant: 5).isActive = true
        self.ratingView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func avatarDidUpdate() {
        self.avatarImageView.image = self.app?.avatar
    }
}
