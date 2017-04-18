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

class ImageMessageCell: MessageCell {

    var attachedImageView: UIImageView = {
        let view = UIImageView()

        view.contentMode = .scaleAspectFit
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8

        return view
    }()

    override class func reuseIdentifier() -> String {
        return "TGImageMessageCell"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.bubbleView.addSubview(self.bubbleImageView)
        self.bubbleImageView.addSubview(self.attachedImageView)
        self.bubbleImageView.addSubview(self.timeLabel)
        self.bubbleImageView.addSubview(self.deliveryStatusView)

        self.deliveryStatusView.clipsToBounds = true
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var layout: NOCChatItemCellLayout? {
        didSet {
            guard let cellLayout = self.layout as? ImageMessageCellLayout else {
                fatalError("Invalid layout type.")
            }

            self.bubbleView.frame = cellLayout.bubbleViewFrame
            self.bubbleImageView.frame = cellLayout.bubbleImageViewFrame
            self.bubbleImageView.image = self.isHighlight ? cellLayout.highlightBubbleImage : cellLayout.bubbleImage
            self.bubbleImageView.tintColor = cellLayout.isOutgoing ? Theme.outgoingMessageBackgroundColor : Theme.incomingMessageBackgroundColor

            self.attachedImageView.image = nil
            self.attachedImageView.frame = .zero

            if let image = cellLayout.message.images.first {
                self.attachedImageView.image = image
                self.attachedImageView.frame = cellLayout.attachedImageViewFrame
            }

            self.deliveryStatusView.frame = cellLayout.deliveryStatusViewFrame
            self.deliveryStatusView.deliveryStatus = cellLayout.message.deliveryStatus
            self.deliveryStatusView.tintColor = cellLayout.isOutgoing ? Theme.outgoingMessageTextColor : Theme.incomingMessageTextColor

            let timeAttributedString = NSMutableAttributedString(attributedString: (cellLayout.attributedTime ?? NSAttributedString()))
            let range = NSRange(location: 0, length: timeAttributedString.length)
            timeAttributedString.addAttributes([NSForegroundColorAttributeName: Theme.lightTextColor, NSStrokeColorAttributeName: Theme.darkTextColor, NSStrokeWidthAttributeName: -1.0], range: range)
            self.timeLabel.attributedText = timeAttributedString
        }
    }
}
