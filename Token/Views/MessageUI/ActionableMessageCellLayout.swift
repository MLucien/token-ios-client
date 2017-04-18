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

class ActionableMessageCellLayout: MessageCellLayout {

    var attributedTitle: NSAttributedString? {
        return self.message.attributedTitle
    }

    var attributedSubtitle: NSAttributedString? {
        return self.message.attributedSubtitle
    }

    override var attributedTime: NSAttributedString? {
        get {
            return NSAttributedString()
        }
        set {}
    }

    var subtitleLabelFrame: CGRect = .zero
    var titleLabelFrame: CGRect = .zero

    var rejectButtonFrame: CGRect = .zero
    var acceptButtonFrame: CGRect = .zero

    required init(chatItem: NOCChatItem, cellWidth width: CGFloat) {
        super.init(chatItem: chatItem, cellWidth: width)

        self.reuseIdentifier = "TGActionableTextMessageCell"
    }

    override func calculate() {
        self.height = 0
        self.titleLabelFrame = .zero
        self.subtitleLabelFrame = .zero
        self.rejectButtonFrame = .zero
        self.acceptButtonFrame = .zero
        self.bubbleViewFrame = .zero
        self.bubbleImageViewFrame = .zero
        self.textLabelFrame = .zero
        self.textLayout = nil
        self.timeLabelFrame = .zero
        self.deliveryStatusViewFrame = .zero

        guard let text = self.attributedText, let time = self.attributedTime else {
            return
        }

        // dynamic font support
        let dynamicFont = Style.textFont
        text.yy_setAttribute(NSFontAttributeName, value: dynamicFont)

        let preferredMaxBubbleWidth = ceil(self.width * 0.85)
        var bubbleViewWidth = preferredMaxBubbleWidth

        // prelayout
        let unlimitSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let timeLabelSize = time.boundingRect(with: unlimitSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
        let timeLabelWidth = timeLabelSize.width
        let timeLabelHeight = CGFloat(15)

        let hPadding = CGFloat(8)
        let vPadding = CGFloat(4)

        let textMargin = self.isOutgoing ? UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 15) : UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 10)
        var textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right - hPadding - timeLabelWidth - hPadding / 2

        let modifier = TGTextLinePositionModifier()
        modifier.font = dynamicFont
        modifier.paddingTop = 2
        modifier.paddingBottom = 2

        let container = YYTextContainer()
        container.size = CGSize(width: textLabelWidth, height: CGFloat.greatestFiniteMagnitude)
        container.linePositionModifier = modifier

        guard let textLayout = YYTextLayout(container: container, text: text) else {
            return
        }

        self.textLayout = textLayout

        var bubbleViewHeight = CGFloat(0)

        // relayout
        if textLayout.rowCount > 1 {
            textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right
            container.size = CGSize(width: textLabelWidth, height: CGFloat.greatestFiniteMagnitude)

            guard let newTextLayout = YYTextLayout(container: container, text: text) else {
                return
            }

            self.textLayout = newTextLayout

            // layout content in bubble
            textLabelWidth = ceil(newTextLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: newTextLayout.rowCount))

            self.textLabelFrame = CGRect(x: textMargin.left, y: textMargin.top, width: textLabelWidth, height: textLabelHeight)

            let tryPoint = CGPoint(x: textLabelWidth - hPadding / 2 - timeLabelWidth - hPadding, y: textLabelHeight - timeLabelHeight / 2)

            let needNewLine = newTextLayout.textRange(at: tryPoint) != nil
            if needNewLine {
                var x = bubbleViewWidth - textMargin.left - hPadding / 2 - timeLabelWidth
                var y = textMargin.top + textLabelHeight

                y += vPadding
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2

                bubbleViewHeight = textMargin.top + textLabelHeight + vPadding + timeLabelHeight + textMargin.bottom
                self.bubbleViewFrame = self.isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            } else {
                bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
                self.bubbleViewFrame = self.isOutgoing ? CGRect(x: self.width - self.bubbleViewMargin.right - bubbleViewWidth, y: self.bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: self.bubbleViewMargin.left, y: self.bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

                var x = bubbleViewWidth - textMargin.right - hPadding / 2 - timeLabelWidth
                let y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
            }

        } else {
            textLabelWidth = ceil(textLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: textLayout.rowCount))

            bubbleViewWidth = textMargin.left + textLabelWidth + hPadding + timeLabelWidth + hPadding / 2 + textMargin.right
            bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
            self.bubbleViewFrame = self.isOutgoing ? CGRect(x: self.width - self.bubbleViewMargin.right - bubbleViewWidth, y: self.bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: self.bubbleViewMargin.left, y: self.bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

            self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            var x = textMargin.left
            var y = textMargin.top
            self.textLabelFrame = CGRect(x: x, y: y, width: textLabelWidth, height: textLabelHeight)

            x += textLabelWidth + hPadding
            y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
            self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

            x += timeLabelWidth + hPadding / 2
        }

        if let attributedTitle = self.attributedTitle {
            let textLabelWidth = min(preferredMaxBubbleWidth, attributedTitle.boundingRect(with: .zero, options: [], context: nil).integral.width)
            let size = attributedTitle.boundingRect(with: CGSize(width: textLabelWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
            self.titleLabelFrame = CGRect(x: self.textLabelFrame.origin.x, y: textMargin.top, width: size.width, height: size.height)

            let diff = self.titleLabelFrame.height + textMargin.top
            let width = textMargin.left + textLabelWidth + hPadding + hPadding / 2 + textMargin.right

            bubbleViewHeight += diff
            self.textLabelFrame.origin.y += diff
            self.bubbleImageViewFrame.size.height = bubbleViewHeight
            self.bubbleImageViewFrame.size.width = max(self.bubbleImageViewFrame.width, width)
            self.bubbleViewFrame.size.height = bubbleViewHeight
            self.bubbleViewFrame.size.width = max(self.bubbleViewFrame.width, width)

            self.bubbleViewFrame.origin.x = min(self.bubbleViewFrame.origin.x, self.isOutgoing ? (self.width - self.bubbleViewMargin.right - width) : self.bubbleViewMargin.left)
        }

        if let attributedSubtitle = self.attributedSubtitle {
            let textLabelWidth = min(preferredMaxBubbleWidth, attributedSubtitle.boundingRect(with: .zero, options: [], context: nil).integral.width)
            let size = attributedSubtitle.boundingRect(with: CGSize(width: textLabelWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
            let top = textMargin.top + self.titleLabelFrame.maxY
            self.subtitleLabelFrame = CGRect(x: self.textLabelFrame.origin.x, y: top, width: size.width, height: size.height)

            let diff = self.subtitleLabelFrame.height + textMargin.top
            let width = textMargin.left + textLabelWidth + hPadding + hPadding / 2 + textMargin.right

            bubbleViewHeight += diff
            self.textLabelFrame.origin.y += diff
            self.bubbleImageViewFrame.size.height = bubbleViewHeight
            self.bubbleImageViewFrame.size.width = max(self.bubbleImageViewFrame.width, width)
            self.bubbleViewFrame.size.height = bubbleViewHeight
            self.bubbleViewFrame.size.width = max(self.bubbleViewFrame.width, width)

            self.bubbleViewFrame.origin.x = min(self.bubbleViewFrame.origin.x, self.isOutgoing ? (self.width - self.bubbleViewMargin.right - width) : self.bubbleViewMargin.left)
        }

        if let item = self.chatItem as? Message, item.isActionable {
            let height: CGFloat = 44.0
            let x: CGFloat = 4.0
            let buttonWidth = (self.bubbleImageViewFrame.width / 2) - 2

            self.rejectButtonFrame = CGRect(x: x, y: bubbleViewHeight, width: buttonWidth, height: height)
            self.acceptButtonFrame = CGRect(x: x + buttonWidth - 1, y: bubbleViewHeight, width: buttonWidth, height: height)

            bubbleViewHeight += self.rejectButtonFrame.height
            self.bubbleImageViewFrame.size.height = bubbleViewHeight
            self.bubbleViewFrame.size.height = bubbleViewHeight
        }

        self.height = bubbleViewHeight + self.bubbleViewMargin.top + self.bubbleViewMargin.bottom
    }
}
