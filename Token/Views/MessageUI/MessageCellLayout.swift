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

class MessageCellLayout: TGBaseMessageCellLayout {

    var attributedTime: NSAttributedString?
    var bubbleImage: UIImage?
    var highlightBubbleImage: UIImage?

    var bubbleImageViewFrame = CGRect.zero
    var textLabelFrame = CGRect.zero
    var textLayout: YYTextLayout?
    var timeLabelFrame = CGRect.zero
    var deliveryStatusViewFrame = CGRect.zero

    var attributedText: NSMutableAttributedString?

    required init(chatItem: NOCChatItem, cellWidth width: CGFloat) {
        super.init(chatItem: chatItem, cellWidth: width)

        self.reuseIdentifier = "TGTextMessageCell"

        self.setupAttributedText()
        self.setupAttributedTime()
        self.setupBubbleImage()
        self.calculate()
    }

    private func setupAttributedText() {
        let text = self.message.text
        let attributedText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: Style.textFont, NSForegroundColorAttributeName: self.isOutgoing ? Theme.outgoingMessageTextColor : Theme.incomingMessageTextColor])

        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)
        if let detect = detector {
            let matches = detect.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.characters.count))
            for match in matches {
                let highlightBorder = YYTextBorder()
                highlightBorder.insets = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
                highlightBorder.cornerRadius = 2
                highlightBorder.fillColor = Style.linkBackgroundColor

                let highlight = YYTextHighlight(backgroundColor: nil)
                highlight.setColor(Style.linkColor)
                highlight.setBackgroundBorder(highlightBorder)
                highlight.userInfo = ["url": match.url!]

                attributedText.yy_setColor(Style.linkColor, range: match.range)
                attributedText.yy_setTextHighlight(highlight, range: match.range)
            }
        }

        self.attributedText = attributedText
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
        self.bubbleViewFrame = CGRect.zero
        self.bubbleImageViewFrame = CGRect.zero
        self.textLabelFrame = CGRect.zero
        self.textLayout = nil
        self.timeLabelFrame = CGRect.zero
        self.deliveryStatusViewFrame = CGRect.zero

        guard let text = self.attributedText, text.length > 0, let time = self.attributedTime else {
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

        let deliveryStatusWidth: CGFloat = (self.isOutgoing && self.message.deliveryStatus != .unsent) ? 15 : 0
        let deliveryStatusHeight = deliveryStatusWidth

        let hPadding = CGFloat(8)
        let vPadding = CGFloat(4)

        let textMargin = self.isOutgoing ? UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 15) : UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 10)
        var textLabelWidth = bubbleViewWidth - textMargin.left - textMargin.right - hPadding - timeLabelWidth - hPadding / 2 - deliveryStatusWidth

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

            let tryPoint = CGPoint(x: textLabelWidth - deliveryStatusWidth - hPadding / 2 - timeLabelWidth - hPadding, y: textLabelHeight - timeLabelHeight / 2)

            let needNewLine = newTextLayout.textRange(at: tryPoint) != nil
            if needNewLine {
                var x = bubbleViewWidth - textMargin.left - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
                var y = textMargin.top + textLabelHeight

                y += vPadding
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
                self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)

                bubbleViewHeight = textMargin.top + textLabelHeight + vPadding + timeLabelHeight + textMargin.bottom
                self.bubbleViewFrame = isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            } else {
                bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
                self.bubbleViewFrame = isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

                self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

                var x = bubbleViewWidth - textMargin.right - deliveryStatusWidth - hPadding / 2 - timeLabelWidth
                let y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
                self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

                x += timeLabelWidth + hPadding / 2
                self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)
            }

        } else {
            textLabelWidth = ceil(textLayout.textBoundingSize.width)
            let textLabelHeight = ceil(modifier.height(forLineCount: textLayout.rowCount))

            bubbleViewWidth = textMargin.left + textLabelWidth + hPadding + timeLabelWidth + hPadding / 2 + deliveryStatusWidth + textMargin.right
            bubbleViewHeight = textLabelHeight + textMargin.top + textMargin.bottom
            self.bubbleViewFrame = isOutgoing ? CGRect(x: width - bubbleViewMargin.right - bubbleViewWidth, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight) : CGRect(x: bubbleViewMargin.left, y: bubbleViewMargin.top, width: bubbleViewWidth, height: bubbleViewHeight)

            self.bubbleImageViewFrame = CGRect(x: 0, y: 0, width: bubbleViewWidth, height: bubbleViewHeight)

            var x = textMargin.left
            var y = textMargin.top
            self.textLabelFrame = CGRect(x: x, y: y, width: textLabelWidth, height: textLabelHeight)

            x += textLabelWidth + hPadding
            y = bubbleViewHeight - textMargin.bottom - timeLabelHeight
            self.timeLabelFrame = CGRect(x: x, y: y, width: timeLabelWidth, height: timeLabelHeight)

            x += timeLabelWidth + hPadding / 2
            self.deliveryStatusViewFrame = CGRect(x: x, y: y, width: deliveryStatusWidth, height: deliveryStatusHeight)
        }

        self.height = self.bubbleImageViewFrame.height + self.bubbleViewMargin.top + self.bubbleViewMargin.bottom
    }

    struct Style {
        static let outgoingBubbleImage = #imageLiteral(resourceName: "TGBubbleOutgoing").withRenderingMode(.alwaysTemplate)
        static let highlightOutgoingBubbleImage = #imageLiteral(resourceName: "TGBubbleOutgoingHL").withRenderingMode(.alwaysTemplate)

        static let incomingBubbleImage = #imageLiteral(resourceName: "TGBubbleIncoming").withRenderingMode(.alwaysTemplate)
        static let highlightIncomingBubbleImage = #imageLiteral(resourceName: "TGBubbleIncomingHL").withRenderingMode(.alwaysTemplate)

        static var textFont: UIFont {
            return Theme.medium(size: UIFont.preferredFont(forTextStyle: .body).pointSize)
        }

        static let linkColor = UIColor(colorLiteralRed: 0 / 255.0, green: 75 / 255.0, blue: 173 / 255.0, alpha: 1)
        static let linkBackgroundColor = UIColor(colorLiteralRed: 191 / 255.0, green: 223 / 255.0, blue: 254 / 255.0, alpha: 1)

        static let timeFont = UIFont.systemFont(ofSize: 12)
        static let outgoingTimeColor = Theme.lighterGreyTextColor
        static let incomingTimeColor = Theme.greyTextColor

        static let timeFormatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "h:mm a"
            return df
        }()
    }
}

class TGTextLinePositionModifier: NSObject, YYTextLinePositionModifier {

    var font = UIFont.systemFont(ofSize: 16)
    var paddingTop = CGFloat(0)
    var paddingBottom = CGFloat(0)
    var lineHeightMultiple = CGFloat(0)

    override init() {
        super.init()

        if #available(iOS 9.0, *) {
            self.lineHeightMultiple = 1.34 // for PingFang SC
        } else {
            self.lineHeightMultiple = 1.3125 // for Heiti SC
        }
    }

    func modifyLines(_ lines: [YYTextLine], fromText _: NSAttributedString, in _: YYTextContainer) {
        let ascent = self.font.pointSize * 0.86

        let lineHeight = self.font.pointSize * lineHeightMultiple
        for line in lines {
            var position = line.position
            position.y = self.paddingTop + ascent + CGFloat(line.row) * lineHeight
            line.position = position
        }
    }

    func copy(with _: NSZone? = nil) -> Any {
        let one = TGTextLinePositionModifier()
        one.font = font
        one.paddingTop = paddingTop
        one.paddingBottom = paddingBottom
        one.lineHeightMultiple = lineHeightMultiple

        return one
    }

    func height(forLineCount lineCount: UInt) -> CGFloat {
        if lineCount == 0 {
            return 0
        }

        let ascent = self.font.pointSize * 0.86
        let descent = self.font.pointSize * 0.14
        let lineHeight = self.font.pointSize * lineHeightMultiple

        return self.paddingTop + self.paddingBottom + ascent + descent + CGFloat(lineCount - 1) * lineHeight
    }
}
