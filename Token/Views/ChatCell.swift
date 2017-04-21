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
import SweetFoundation

/// ChatsTableController cells.
class ChatCell: UITableViewCell {
    var thread: TSThread? {
        didSet {
            // last visible message
            if let message = self.thread?.messages.last, let messageBody = message.body {
                switch SofaType(sofa: messageBody) {
                case .message:
                    self.lastMessageLabel.text = SofaMessage(content: messageBody).body
                case .paymentRequest:
                    self.lastMessageLabel.text = SofaPaymentRequest(content: messageBody).body
                default:
                    self.lastMessageLabel.text = nil
                }
            } else {
                self.lastMessageLabel.text = nil
            }

            // date
            if let date = self.thread?.lastMessageDate() {
                if DateTimeFormatter.isDate(date, sameDayAs: Date()) {
                    self.lastMessageDateLabel.text = DateTimeFormatter.timeFormatter.string(from: date)
                } else {
                    self.lastMessageDateLabel.text = DateTimeFormatter.dateFormatter.string(from: date)
                }
            }

            // unread badge
            if let thread = self.thread {
                let count = TSMessagesManager.shared().unreadMessages(in: thread)
                if count > 0 {
                    self.unreadLabel.text = "\(count)"
                    self.unreadLabel.isHidden = false
                } else {
                    self.unreadLabel.text = nil
                    self.unreadLabel.isHidden = true
                }
            }

            guard let delegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            if let contact = delegate.contactsManager.tokenContact(forAddress: self.thread?.contactIdentifier() ?? "") {
                self.updateContact(contact)
            } else {
                IDAPIClient.shared.findContact(name: self.thread?.contactIdentifier() ?? "") { contact in
                    guard let contact = contact else { return }
                    self.updateContact(contact)
                }
            }
        }
    }

    lazy var unreadLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textAlignment = .center
        view.font = Theme.medium(size: 12)
        view.textColor = Theme.lightTextColor
        view.backgroundColor = Theme.tintColor

        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true

        return view
    }()

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.semibold(size: 15)

        return view
    }()

    lazy var lastMessageLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 14)
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var lastMessageDateLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 14)
        view.textAlignment = .right
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.unreadLabel)
        self.contentView.addSubview(self.avatarImageView)
        self.contentView.addSubview(self.usernameLabel)
        self.contentView.addSubview(self.lastMessageLabel)
        self.contentView.addSubview(self.lastMessageDateLabel)
        self.contentView.addSubview(self.separatorView)

        let height: CGFloat = 24.0
        let margin: CGFloat = 16.0

        self.avatarImageView.set(height: 44)
        self.avatarImageView.set(width: 44)
        self.avatarImageView.cornerRadius = 22

        self.avatarImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin).isActive = true

        self.usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.self.lastMessageDateLabel.leftAnchor, constant: -margin).isActive = true

        self.lastMessageDateLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.lastMessageDateLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
        self.lastMessageDateLabel.rightAnchor.constraint(equalTo: self.self.contentView.rightAnchor, constant: -margin).isActive = true

        self.unreadLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        self.unreadLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.unreadLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.unreadLabel.topAnchor.constraint(equalTo: self.lastMessageDateLabel.bottomAnchor).isActive = true
        self.unreadLabel.rightAnchor.constraint(equalTo: self.self.contentView.rightAnchor, constant: -margin).isActive = true

        self.lastMessageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.lastMessageLabel.topAnchor.constraint(equalTo: self.lastMessageDateLabel.bottomAnchor).isActive = true
        self.lastMessageLabel.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor).isActive = true
        self.lastMessageLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: margin).isActive = true
        self.lastMessageLabel.rightAnchor.constraint(equalTo: self.unreadLabel.leftAnchor, constant: -margin).isActive = true
        self.lastMessageLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin).isActive = true

        self.separatorView.set(height: Theme.borderHeight)
        self.separatorView.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    func updateContact(_ contact: TokenContact) {
        self.usernameLabel.text = contact.name.length > 0 ? contact.name : contact.displayUsername
        self.thread?.cachedContactIdentifier = self.usernameLabel.text
        self.avatarImageView.image = contact.avatar

        if contact.avatar == nil {
            IDAPIClient.shared.downloadAvatar(path: contact.avatarPath) { image in
                self.avatarImageView.image = image
            }
        }
    }
}
