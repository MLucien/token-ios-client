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

open class RatingView: UIView {

    private var starSize: CGFloat = 12
    private var rating: Int = 0
    private(set) var numberOfStars: Int

    private lazy var backgroundStars: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.mask = self.starsMask
        view.backgroundColor = Theme.ratingBackground

        return view
    }()

    private lazy var ratingStars: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.mask = self.starsMask
        view.backgroundColor = Theme.ratingTint

        return view
    }()

    private lazy var ratingConstraint: NSLayoutConstraint = {
        self.ratingStars.widthAnchor.constraint(equalToConstant: 0)
    }()

    init(numberOfStars: Int = 5, customStarSize: CGFloat? = nil) {
        self.numberOfStars = numberOfStars

        super.init(frame: .zero)

        if let customStarSize = customStarSize {
            self.starSize = customStarSize
            self.backgroundStars.backgroundColor = Theme.greyTextColor
        }

        self.addSubview(self.backgroundStars)

        NSLayoutConstraint.activate([
            self.backgroundStars.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundStars.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.backgroundStars.widthAnchor.constraint(equalToConstant: self.starSize * CGFloat(numberOfStars)).priority(.high),
            self.backgroundStars.heightAnchor.constraint(equalToConstant: self.starSize).priority(.high),
        ])

        self.addSubview(self.ratingStars)

        NSLayoutConstraint.activate([
            self.ratingStars.topAnchor.constraint(equalTo: self.topAnchor),
            self.ratingStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.ratingStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])

        self.ratingConstraint.isActive = true
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    func set(rating: Float, animated: Bool = false) {
        let denominator: Float = 2
        let roundedRating = round(rating * denominator) / denominator

        self.rating = Int(min(Float(self.numberOfStars), max(0, roundedRating)))
        self.ratingConstraint.constant = self.starSize * CGFloat(roundedRating)

        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .easeOut, animations: {
                self.layoutIfNeeded()
            }, completion: nil)
        } else {
            self.layoutIfNeeded()
        }
    }

    var starsMask: CALayer {
        let starRadius = self.starSize / 2

        let mask = CAShapeLayer()
        mask.frame = CGRect(x: 0, y: 0, width: self.starSize, height: self.starSize)
        mask.position = CGPoint(x: starRadius, y: starRadius)

        var mutablePath: CGMutablePath?

        for i in 0 ..< self.numberOfStars {

            if let mutablePath = mutablePath {
                mutablePath.addPath(self.starPath(with: starRadius, offset: CGFloat(i) * self.starSize))
            } else {
                mutablePath = self.starPath(with: starRadius).mutableCopy()
            }
        }

        mask.path = mutablePath

        return mask
    }

    func starPath(with radius: CGFloat, offset: CGFloat = 0) -> CGPath {
        let center = CGPoint(x: radius, y: radius)
        let theta = CGFloat(Double.pi * 2) * (2 / 5)
        let flipVertical: CGFloat = -1

        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: radius * center.y * flipVertical))

        for i in 0 ..< 6 {
            let x = radius * sin(CGFloat(i) * theta) + offset
            let y = radius * cos(CGFloat(i) * theta)
            path.addLine(to: CGPoint(x: x + center.x, y: (y * flipVertical) + center.y))
        }

        path.close()

        return path.cgPath
    }
}
