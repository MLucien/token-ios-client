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

import Foundation
import NoChat

public class Message: NSObject, NOCChatItem {

    public var messageId: String = UUID().uuidString
    public var messageType: String = "Text"

    public let signalMessage: TSMessage

    public var attributedTitle: NSAttributedString?
    public var attributedSubtitle: NSAttributedString?

    public var images: [UIImage] {
        if self.signalMessage.hasAttachments() {
            if let attachmentId = (signalMessage.attachmentIds as? [String])?.first {
                let attachment = TSAttachment.fetch(withUniqueID: attachmentId)!
                if attachment is TSAttachmentPointer {
                    return [#imageLiteral(resourceName: "placeholder")]
                } else if let stream = attachment as? TSAttachmentStream, let image = stream.image() {
                    return [image]
                }
            }
        }

        return []
    }

    public var title: String? {
        set {
            if let string = newValue {
                self.attributedTitle = NSAttributedString(string: string, attributes: [NSFontAttributeName: Theme.semibold(size: 15), NSForegroundColorAttributeName: Theme.incomingMessageTextColor])
            } else {
                self.attributedTitle = nil
            }
        }
        get {
            return self.attributedTitle?.string
        }
    }

    public var subtitle: String? {
        set {
            if let string = newValue {
                self.attributedSubtitle = NSAttributedString(string: string, attributes: [NSFontAttributeName: Theme.regular(size: 15), NSForegroundColorAttributeName: Theme.incomingMessageTextColor])
            } else {
                self.attributedSubtitle = nil
            }
        }
        get {
            return self.attributedSubtitle?.string
        }
    }

    public var senderId: String = ""
    public var date: Date

    public var isOutgoing: Bool = true
    public var isActionable: Bool

    public var deliveryStatus: TSOutgoingMessageState {
        return (self.signalMessage as? TSOutgoingMessage)?.messageState ?? .attemptingOut
    }

    public var sofaWrapper: SofaWrapper?

    public var isDisplayable: Bool {
        // we are displayable even if there's no sofa content but we have attachments
        guard self.images.isEmpty else { return true }
        // we don't display them if sofa wrapper is nil
        guard let sofaWrapper = self.sofaWrapper else { return false }
        // or not one of the types below
        return [.message, .paymentRequest, .payment, .command].contains(sofaWrapper.type)
    }

    var text: String {
        guard let sofaWrapper = self.sofaWrapper else { return "" }
        switch sofaWrapper.type {
        case .message:
            return (sofaWrapper as! SofaMessage).body
        case .paymentRequest:
            return (sofaWrapper as! SofaPaymentRequest).body
        case .payment:
            return ""
        case .command:
            return (sofaWrapper as! SofaCommand).body
        default:
            return sofaWrapper.content
        }
    }

    public func uniqueIdentifier() -> String {
        return self.messageId
    }

    public func type() -> String {
        return self.messageType
    }

    init(sofaWrapper: SofaWrapper?, signalMessage: TSMessage, date: Date? = nil, isOutgoing: Bool = true, shouldProcess: Bool = false) {
        self.sofaWrapper = sofaWrapper
        self.isOutgoing = isOutgoing
        self.signalMessage = signalMessage
        self.date = date ?? Date()
        self.isActionable = shouldProcess && !isOutgoing && (sofaWrapper?.type == .paymentRequest)

        super.init()
    }
}
