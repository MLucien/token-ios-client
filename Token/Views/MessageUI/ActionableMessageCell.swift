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

import NoChat
import YYText

protocol ActionableCellDelegate {
    func didTapApproveButton(_ messageCell: ActionableMessageCell)

    func didTapRejectButton(_ messageCell: ActionableMessageCell)
}

class ActionableMessageCell: MessageCell {

    var actionsDelegate: ActionableCellDelegate?

    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.adjustsFontSizeToFitWidth = true

        return view
    }()

    lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.adjustsFontSizeToFitWidth = true

        return view
    }()

    lazy var rejectButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapRejectButton), for: .touchUpInside)

        let title = NSAttributedString(string: "✕ Reject", attributes: [NSForegroundColorAttributeName: Theme.greyTextColor, NSFontAttributeName: Theme.regular(size: 16)])
        button.setAttributedTitle(title, for: .normal)

        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapAcceptButton), for: .touchUpInside)

        let title = NSAttributedString(string: "✓ Approve", attributes: [NSForegroundColorAttributeName: Theme.tintColor, NSFontAttributeName: Theme.semibold(size: 16)])
        button.setAttributedTitle(title, for: .normal)

        return button
    }()

    override class func reuseIdentifier() -> String {
        return "TGActionableTextMessageCell"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.bubbleView.addSubview(self.titleLabel)
        self.bubbleView.addSubview(self.subtitleLabel)

        self.bubbleView.addSubview(self.rejectButton)
        self.bubbleView.addSubview(self.acceptButton)

        self.bubbleView.clipsToBounds = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var layout: NOCChatItemCellLayout? {
        didSet {
            guard let cellLayout = self.layout as? ActionableMessageCellLayout else {
                fatalError("invalid layout type")
            }

            self.titleLabel.attributedText = cellLayout.attributedTitle
            self.subtitleLabel.attributedText = cellLayout.attributedSubtitle

            self.titleLabel.frame = cellLayout.titleLabelFrame
            self.subtitleLabel.frame = cellLayout.subtitleLabelFrame

            self.rejectButton.frame = cellLayout.rejectButtonFrame
            self.acceptButton.frame = cellLayout.acceptButtonFrame

            let rejectMask = CAShapeLayer()
            rejectMask.path = UIBezierPath(roundedRect: self.rejectButton.bounds, byRoundingCorners: UIRectCorner.bottomLeft, cornerRadii: CGSize(width: 20, height: 20)).cgPath
            self.rejectButton.layer.mask = rejectMask

            let acceptMask = CAShapeLayer()
            acceptMask.path = UIBezierPath(roundedRect: self.acceptButton.bounds, byRoundingCorners: UIRectCorner.bottomRight, cornerRadii: CGSize(width: 20, height: 20)).cgPath
            self.acceptButton.layer.mask = acceptMask
        }
    }

    func didTapRejectButton() {
        self.actionsDelegate?.didTapRejectButton(self)
    }

    func didTapAcceptButton() {
        self.actionsDelegate?.didTapApproveButton(self)
    }
}
