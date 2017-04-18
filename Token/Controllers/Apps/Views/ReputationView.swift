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

class ReputationView: UIView {

    var reviewCount: Int = 0 {
        didSet {
            self.ratingsCountLabel.text = "\(String(describing: self.reviewCount)) ratings"
        }
    }

    private lazy var ratingLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.light(size: 49)
        label.textColor = Theme.ratingTint
        label.textAlignment = .center

        return label
    }()

    private lazy var ratingView: RatingView = {
        let view = RatingView()
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var ratingsCountLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.regular(size: 14)

        return label
    }()

    private lazy var fiveStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)

        return view
    }()

    private lazy var fourStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)

        return view
    }()

    private lazy var threeStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)

        return view
    }()

    private lazy var twoStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)

        return view
    }()

    private lazy var oneStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)

        return view
    }()

    private lazy var guides: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide()]
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviewsAndConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.layoutIfNeeded()
        self.setScore(.zero)
    }

    func addSubviewsAndConstraints() {

        for guide in guides {
            self.addLayoutGuide(guide)
        }

        self.addSubview(self.ratingLabel)
        self.addSubview(self.ratingView)
        self.addSubview(self.ratingsCountLabel)

        self.addSubview(self.fiveStarsBarView)
        self.addSubview(self.fourStarsBarView)
        self.addSubview(self.threeStarsBarView)
        self.addSubview(self.twoStarsBarView)
        self.addSubview(self.oneStarsBarView)

        let horizontalMargin: CGFloat = 16
        let barHeight: CGFloat = 18
        let barSpacing: CGFloat = 2

        NSLayoutConstraint.activate([
            self.guides[0].topAnchor.constraint(equalTo: self.topAnchor),
            self.guides[0].leftAnchor.constraint(equalTo: self.leftAnchor),
            self.guides[0].bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.guides[1].topAnchor.constraint(equalTo: self.topAnchor),
            self.guides[1].leftAnchor.constraint(equalTo: self.guides[0].rightAnchor),
            self.guides[1].bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.guides[1].rightAnchor.constraint(equalTo: self.rightAnchor),

            self.ratingLabel.topAnchor.constraint(equalTo: self.guides[0].topAnchor, constant: -5),
            self.ratingLabel.leftAnchor.constraint(equalTo: self.guides[0].leftAnchor, constant: horizontalMargin),
            self.ratingLabel.rightAnchor.constraint(equalTo: self.guides[0].rightAnchor, constant: -horizontalMargin),

            self.ratingView.topAnchor.constraint(equalTo: self.ratingLabel.bottomAnchor, constant: 0),
            self.ratingView.centerXAnchor.constraint(equalTo: self.guides[0].centerXAnchor),

            self.ratingsCountLabel.topAnchor.constraint(equalTo: self.ratingView.bottomAnchor, constant: 10),
            self.ratingsCountLabel.centerXAnchor.constraint(equalTo: self.guides[0].centerXAnchor),

            self.fiveStarsBarView.topAnchor.constraint(equalTo: self.guides[1].topAnchor, constant: barSpacing),
            self.fiveStarsBarView.leftAnchor.constraint(equalTo: self.guides[1].leftAnchor, constant: horizontalMargin),
            self.fiveStarsBarView.rightAnchor.constraint(equalTo: self.guides[1].rightAnchor, constant: -horizontalMargin),
            self.fiveStarsBarView.heightAnchor.constraint(equalToConstant: barHeight),

            self.fourStarsBarView.topAnchor.constraint(equalTo: self.fiveStarsBarView.bottomAnchor, constant: barSpacing),
            self.fourStarsBarView.leftAnchor.constraint(equalTo: self.guides[1].leftAnchor, constant: horizontalMargin),
            self.fourStarsBarView.rightAnchor.constraint(equalTo: self.guides[1].rightAnchor, constant: -horizontalMargin),
            self.fourStarsBarView.heightAnchor.constraint(equalToConstant: barHeight),

            self.threeStarsBarView.topAnchor.constraint(equalTo: self.fourStarsBarView.bottomAnchor, constant: barSpacing),
            self.threeStarsBarView.leftAnchor.constraint(equalTo: self.guides[1].leftAnchor, constant: horizontalMargin),
            self.threeStarsBarView.rightAnchor.constraint(equalTo: self.guides[1].rightAnchor, constant: -horizontalMargin),
            self.threeStarsBarView.heightAnchor.constraint(equalToConstant: barHeight),

            self.twoStarsBarView.topAnchor.constraint(equalTo: self.threeStarsBarView.bottomAnchor, constant: barSpacing),
            self.twoStarsBarView.leftAnchor.constraint(equalTo: self.guides[1].leftAnchor, constant: horizontalMargin),
            self.twoStarsBarView.rightAnchor.constraint(equalTo: self.guides[1].rightAnchor, constant: -horizontalMargin),
            self.twoStarsBarView.heightAnchor.constraint(equalToConstant: barHeight),

            self.oneStarsBarView.topAnchor.constraint(equalTo: self.twoStarsBarView.bottomAnchor, constant: barSpacing),
            self.oneStarsBarView.leftAnchor.constraint(equalTo: self.guides[1].leftAnchor, constant: horizontalMargin),
            self.oneStarsBarView.rightAnchor.constraint(equalTo: self.guides[1].rightAnchor, constant: -horizontalMargin),
            self.oneStarsBarView.heightAnchor.constraint(equalToConstant: barHeight),
            self.oneStarsBarView.bottomAnchor.constraint(equalTo: self.guides[1].bottomAnchor, constant: -barSpacing),
        ])
    }

    public func setScore(_ ratingScore: RatingScore) {
        self.reviewCount = ratingScore.count
        self.ratingLabel.text = "\(ratingScore.score)"
        self.ratingView.set(rating: Float(ratingScore.score))

        let count = ratingScore.count == 0 ? 1 : ratingScore.count

        self.fiveStarsBarView.numberOfStars = 5
        self.fiveStarsBarView.percentage = CGFloat(ratingScore.stars.five) / CGFloat(count)

        self.fourStarsBarView.numberOfStars = 4
        self.fourStarsBarView.percentage = CGFloat(ratingScore.stars.four) / CGFloat(count)

        self.threeStarsBarView.numberOfStars = 3
        self.threeStarsBarView.percentage = CGFloat(ratingScore.stars.three) / CGFloat(count)

        self.twoStarsBarView.numberOfStars = 2
        self.twoStarsBarView.percentage = CGFloat(ratingScore.stars.two) / CGFloat(count)

        self.oneStarsBarView.numberOfStars = 1
        self.oneStarsBarView.percentage = CGFloat(ratingScore.stars.one) / CGFloat(count)
    }
}

class ReputationBarView: UIView {
    private lazy var numberLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.greyTextColor
        label.font = Theme.medium(size: 13)

        return label
    }()

    private lazy var starImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "gray-star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    private lazy var barView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.ratingTint
        view.layer.cornerRadius = 2.0

        return view
    }()

    var numberOfStars: Int = 0 {
        didSet {
            self.numberLabel.text = String(describing: self.numberOfStars)
        }
    }

    var percentage: CGFloat = 0 {
        didSet {
            self.barWidthAnchor.constant = (self.percentage * self.totalWidth)
        }
    }

    lazy var barWidthAnchor: NSLayoutConstraint = {
        self.barView.widthAnchor.constraint(equalToConstant: self.totalWidth)
    }()

    let totalWidth: CGFloat = 180

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.numberLabel)
        self.addSubview(self.starImageView)
        self.addSubview(self.barView)

        NSLayoutConstraint.activate([
            self.numberLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.numberLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.numberLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.numberLabel.widthAnchor.constraint(equalToConstant: 8),

            self.starImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.starImageView.leftAnchor.constraint(equalTo: self.numberLabel.rightAnchor, constant: 5),

            self.barView.topAnchor.constraint(equalTo: self.topAnchor),
            self.barView.leftAnchor.constraint(equalTo: self.starImageView.rightAnchor, constant: 8),
            self.barView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.barWidthAnchor,
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
