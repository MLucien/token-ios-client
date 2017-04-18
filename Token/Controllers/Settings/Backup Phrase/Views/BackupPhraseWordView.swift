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

class BackupPhraseWordView: UIControl {

    static let height: CGFloat = 35

    private lazy var background: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.addDashedBorder()

        return view
    }()

    private lazy var backgroundOverlay: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        view.alpha = 0

        return view
    }()

    private lazy var wordLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.darkTextColor
        view.textAlignment = .center
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    var word: Word?

    convenience init(with word: Word) {
        self.init(withAutoLayout: true)
        self.word = word

        self.wordLabel.text = word

        self.addSubview(self.background)
        self.background.addSubview(self.backgroundOverlay)
        self.addSubview(self.wordLabel)

        NSLayoutConstraint.activate([
            self.background.topAnchor.constraint(equalTo: self.topAnchor),
            self.background.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.background.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.background.rightAnchor.constraint(equalTo: self.rightAnchor),

            self.backgroundOverlay.topAnchor.constraint(equalTo: self.topAnchor, constant: 1),
            self.backgroundOverlay.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 1),
            self.backgroundOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
            self.backgroundOverlay.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -1),

            self.wordLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.wordLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
            self.wordLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.wordLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10),

            self.heightAnchor.constraint(equalToConstant: BackupPhraseWordView.height).priority(.high),
        ])

        self.setNeedsLayout()
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.layoutBorder()
    }

    func layoutBorder() {

        for shape in self.shapeLayers {
            shape.bounds = self.bounds
            shape.position = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
            shape.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 4).cgPath
        }
    }

    func setBorder(dashed: Bool) {

        for shape in self.shapeLayers {
            shape.lineDashPattern = dashed ? [5, 5] : nil
        }
    }

    var shapeLayers: [CAShapeLayer] {
        guard let sublayers = self.background.layer.sublayers else { return [] }

        return sublayers.flatMap { layer in
            layer as? CAShapeLayer
        }
    }

    func getSize() -> CGSize {
        self.layoutIfNeeded()
        return self.frame.size
    }

    var isAddedForVerification: Bool = false {
        didSet {
            UIView.highlightAnimation {
                self.wordLabel.alpha = self.isAddedForVerification ? 0 : 1
                self.background.backgroundColor = self.isAddedForVerification ? nil : Theme.lightTextColor
                self.alpha = self.isAddedForVerification ? 0.6 : 1
                self.setBorder(dashed: self.isAddedForVerification)
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted != oldValue {
                self.feedbackGenerator.impactOccurred()

                UIView.highlightAnimation {
                    self.backgroundOverlay.alpha = self.isHighlighted ? 1 : 0
                }
            }
        }
    }
}

extension UIView {

    func addDashedBorder() {

        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.withAlphaComponent(0.1).cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = kCALineJoinRound
        self.layer.addSublayer(shapeLayer)
    }
}
