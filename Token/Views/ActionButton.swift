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

class ActionButton: UIControl {

    static let height: CGFloat = 44

    var titleColor = StateColor()
    var buttonColor = StateColor()
    var borderColor = StateColor()

    struct StateColor {
        var color: [String: UIColor] = [:]

        subscript(state: ButtonState) -> UIColor? {
            get {
                return color[state.key]
            } set {
                color[state.key] = newValue
            }
        }
    }

    enum ButtonState: String {
        case normal
        case highlighted
        case disabled

        var key: String {
            return self.rawValue
        }
    }

    var buttonState: ButtonState = .normal {
        didSet {
            self.restyle()
        }
    }

    enum ButtonStyle {
        case primary
        case secondary
        case plain
    }

    var style: ButtonStyle? {
        get {
            return self.style
        } set {
            guard let style = newValue else { return }

            switch style {
            case .primary:
                // Primary buttons have the tint color as background with a light text color
                self.titleColor[.normal] = Theme.lightTextColor
                self.buttonColor[.normal] = Theme.tintColor
                self.borderColor[.normal] = Theme.tintColor

                self.titleColor[.highlighted] = Theme.lightTextColor
                self.buttonColor[.highlighted] = Theme.tintColor
                self.borderColor[.highlighted] = Theme.tintColor

                self.titleColor[.disabled] = Theme.lightTextColor
                self.buttonColor[.disabled] = Theme.greyTextColor
                self.borderColor[.disabled] = Theme.greyTextColor
            case .secondary:
                // Secondary buttons have a white background with a dark text color and a border
                self.titleColor[.normal] = Theme.darkTextColor
                self.buttonColor[.normal] = .white
                self.borderColor[.normal] = Theme.greyTextColor

                self.titleColor[.highlighted] = Theme.darkTextColor
                self.buttonColor[.highlighted] = .white
                self.borderColor[.highlighted] = Theme.greyTextColor

                self.titleColor[.disabled] = Theme.greyTextColor
                self.buttonColor[.disabled] = .clear
                self.borderColor[.disabled] = Theme.greyTextColor
            case .plain:
                // Plain buttons have no background with the tint color for the title
                self.titleColor[.normal] = Theme.tintColor
                self.buttonColor[.normal] = .clear
                self.borderColor[.normal] = .clear

                self.titleColor[.highlighted] = Theme.tintColor
                self.buttonColor[.highlighted] = .clear
                self.borderColor[.highlighted] = .clear

                self.titleColor[.disabled] = Theme.greyTextColor
                self.buttonColor[.disabled] = .clear
                self.borderColor[.disabled] = .clear
            }

            self.restyle()
        }
    }

    lazy var background: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.layer.borderWidth = Theme.borderHeight

        return view
    }()

    private lazy var backgroundOverlay: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        view.isUserInteractionEnabled = false
        view.alpha = 0

        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textAlignment = .center
        view.isUserInteractionEnabled = false

        return view
    }()

    lazy var heightConstraint: NSLayoutConstraint = {
        self.heightAnchor.constraint(equalToConstant: ActionButton.height)
    }()

    private lazy var guides: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide()]
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .light)
    }()

    var title: String? {
        didSet {
            guard let title = self.title else { return }
            self.titleLabel.text = title
        }
    }

    convenience init(margin: CGFloat) {
        self.init(frame: .zero)

        self.style = .primary
        self.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.background)
        self.background.addSubview(self.backgroundOverlay)
        self.addSubview(self.titleLabel)

        for guide in self.guides {
            self.addLayoutGuide(guide)
        }

        NSLayoutConstraint.activate([
            self.background.topAnchor.constraint(equalTo: self.topAnchor),
            self.background.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.background.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.background.rightAnchor.constraint(equalTo: self.rightAnchor),

            self.backgroundOverlay.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundOverlay.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundOverlay.rightAnchor.constraint(equalTo: self.rightAnchor),

            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.guides[0].topAnchor.constraint(equalTo: self.topAnchor),
            self.guides[0].leftAnchor.constraint(equalTo: self.leftAnchor),
            self.guides[0].bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.guides[0].rightAnchor.constraint(equalTo: self.titleLabel.leftAnchor),
            self.guides[0].widthAnchor.constraint(greaterThanOrEqualToConstant: margin),

            self.guides[1].topAnchor.constraint(equalTo: self.topAnchor),
            self.guides[1].leftAnchor.constraint(equalTo: self.titleLabel.rightAnchor),
            self.guides[1].bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.guides[1].rightAnchor.constraint(equalTo: self.rightAnchor),
            self.guides[1].widthAnchor.constraint(greaterThanOrEqualToConstant: margin),

            self.guides[0].widthAnchor.constraint(equalTo: self.guides[1].widthAnchor).priority(.high),

            heightConstraint,
        ])
    }

    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted != oldValue {
                self.feedbackGenerator.impactOccurred()

                UIView.highlightAnimation {
                    self.backgroundOverlay.alpha = self.isHighlighted ? 1 : 0
                }

                self.buttonState = self.isHighlighted ? .highlighted : self.isEnabled ? .normal : .disabled

                UIView.highlightAnimation {
                    self.restyle()
                }
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            self.buttonState = self.isEnabled ? .normal : .disabled

            UIView.highlightAnimation {
                self.restyle()
            }
        }
    }

    private func restyle() {
        self.alpha = self.buttonState == .disabled ? 0.6 : 1

        self.titleLabel.textColor = self.titleColor[self.buttonState]
        self.background.backgroundColor = self.buttonColor[self.buttonState]
        self.background.layer.borderColor = self.borderColor[self.buttonState]?.cgColor
    }
}
