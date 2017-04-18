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

class ImageMessageCellLayout: MessageCellLayout {
    var attachedImageViewFrame = CGRect.zero

    required init(chatItem: NOCChatItem, cellWidth width: CGFloat) {
        super.init(chatItem: chatItem, cellWidth: width)

        self.reuseIdentifier = "TGImageMessageCell"

        self.setupAttributedTime()
        self.setupBubbleImage()
        self.calculate()
    }

    private func setupAttributedTime() {
        let timeString = Style.timeFormatter.string(from: message.date)
        let timeColor = self.isOutgoing ? Style.outgoingTimeColor : Style.incomingTimeColor
        self.attributedTime = NSAttributedString(string: timeString, attributes: [NSFontAttributeName: Style.timeFont, NSForegroundColorAttributeName: timeColor])
    }

    private func setupBubbleImage() {
        self.bubbleImage = self.isOutgoing ? Style.outgoingBubbleImage : Style.incomingBubbleImage

        self.highlightBubbleImage = self.isOutgoing ? Style.highlightOutgoingBubbleImage : Style.highlightIncomingBubbleImage
    }

    public override func calculate() {
        self.height = 0
        self.bubbleViewFrame = .zero
        self.bubbleImageViewFrame = .zero
        self.timeLabelFrame = .zero
        self.deliveryStatusViewFrame = .zero
        self.attachedImageViewFrame = .zero

        guard let time = self.attributedTime, let image = self.message.images.first else {
            return
        }

        // prelayout
        let preferredMaxBubbleWidth = ceil(self.width * 0.85)
        var bubbleViewWidth = preferredMaxBubbleWidth

        let unlimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let timeLabelSize = time.boundingRect(with: unlimitSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
        let timeLabelWidth = timeLabelSize.width
        let timeLabelHeight = CGFloat(15)

        let deliveryStatusWidth: CGFloat = (self.isOutgoing && self.message.deliveryStatus != .unsent) ? 15 : 0
        let deliveryStatusHeight = deliveryStatusWidth

        let hPadding = CGFloat(8)

        // image layout
        let aspect = image.size.height / image.size.width
        let bubbleViewHeight = min(preferredMaxBubbleWidth, image.size.width) * aspect
        bubbleViewWidth = min(preferredMaxBubbleWidth, image.size.width)

        self.attachedImageViewFrame = self.isOutgoing ? CGRect(x: self.width - self.bubbleViewMargin.right - bubbleViewWidth, y: 0, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: self.bubbleViewMargin.left, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

        self.bubbleImageViewFrame.size.height = self.attachedImageViewFrame.height

        // time
        var x = bubbleViewWidth - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
        let y = bubbleViewHeight - timeLabelHeight
        self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

        // delivery status
        x += timeLabelWidth + hPadding / 2
        self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)

        // height
        self.height = self.bubbleImageViewFrame.height + self.bubbleViewMargin.top + self.bubbleViewMargin.bottom
    }
}
