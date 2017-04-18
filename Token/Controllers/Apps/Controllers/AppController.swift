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

class AppController: UIViewController {
    var appsAPIClient: AppsAPIClient {
        return AppsAPIClient.shared
    }

    public var app: TokenContact

    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)

        return view
    }()

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.textAlignment = .center
        view.font = Theme.bold(size: 20)

        return view
    }()

    lazy var addContactButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setTitleColor(Theme.darkTextColor, for: .normal)
        view.addTarget(self, action: #selector(didTapAddContactButton), for: .touchUpInside)

        view.layer.cornerRadius = 4.0
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight

        return view
    }()

    lazy var messageContactButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setAttributedTitle(NSAttributedString(string: "Message", attributes: [NSFontAttributeName: Theme.semibold(size: 13)]), for: .normal)
        view.setTitleColor(Theme.darkTextColor, for: .normal)
        view.setTitleColor(Theme.tintColor, for: .highlighted)
        view.addTarget(self, action: #selector(didTapMessageContactButton), for: .touchUpInside)

        view.layer.cornerRadius = 4.0
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0

        return view
    }()

    lazy var reputationSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var reputationTitleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.text = "Reputation"
        view.textColor = .lightGray
        view.font = .systemFont(ofSize: 15)

        return view
    }()

    lazy var reputationView: ReputationView = {
        let view = ReputationView(withAutoLayout: true)

        return view
    }()

    lazy var categorySeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var categoryTitleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.text = "Category"
        view.textColor = Theme.darkTextColor
        view.textColor = .lightGray
        view.font = .systemFont(ofSize: 15)

        return view
    }()

    lazy var categoryContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)

        return view
    }()

    private init() {
        fatalError()
    }

    init(app: TokenContact) {
        self.app = app
        super.init(nibName: nil, bundle: nil)

        self.edgesForExtendedLayout = .bottom
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    open override func loadView() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true

        self.view = scrollView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.addSubviewsAndConstraints()

        self.title = self.app.displayName

        self.updateReputation()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.nameLabel.text = self.app.displayName
        self.categoryContentLabel.text = self.app.category

        if let image = self.app.avatar {
            self.avatarImageView.image = image
        } else {
            AppsAPIClient.shared.downloadImage(for: self.app) { image in
                self.avatarImageView.image = image
            }
        }

        self.updateButton()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func addSubviewsAndConstraints() {
        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.addContactButton)
        self.view.addSubview(self.messageContactButton)

        self.view.addSubview(self.reputationSeparatorView)
        self.view.addSubview(self.reputationTitleLabel)
        self.view.addSubview(self.reputationView)

        self.view.addSubview(self.categorySeparatorView)
        self.view.addSubview(self.categoryTitleLabel)
        self.view.addSubview(self.categoryContentLabel)

        let height: CGFloat = 38.0
        let marginHorizontal: CGFloat = 20.0
        let marginVertical: CGFloat = 16.0
        let avatarSize: CGFloat = 166

        self.avatarImageView.set(height: avatarSize)
        self.avatarImageView.set(width: avatarSize)
        self.avatarImageView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 26).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.nameLabel.set(height: height)
        self.nameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: marginVertical).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.messageContactButton.set(height: height)
        self.messageContactButton.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.messageContactButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.messageContactButton.rightAnchor.constraint(equalTo: self.addContactButton.leftAnchor, constant: -marginHorizontal).isActive = true

        self.messageContactButton.widthAnchor.constraint(equalTo: self.addContactButton.widthAnchor).isActive = true

        self.addContactButton.set(height: height)
        self.addContactButton.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.addContactButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        // We set the view and separator width cosntraints to be the same, to force the scrollview content size to conform to the window
        // otherwise no view is requiring a width of the window, and the scrollview contentSize will shrink to the smallest
        // possible width that satisfy all other constraints.
        self.reputationSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.reputationSeparatorView.set(height: 1.0)
        self.reputationSeparatorView.topAnchor.constraint(equalTo: self.addContactButton.bottomAnchor, constant: marginVertical).isActive = true
        self.reputationSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.reputationSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.reputationTitleLabel.set(height: 32)
        self.reputationTitleLabel.topAnchor.constraint(equalTo: self.reputationSeparatorView.bottomAnchor, constant: marginVertical).isActive = true
        self.reputationTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.reputationTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.reputationView.topAnchor.constraint(equalTo: self.reputationTitleLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.reputationView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.reputationView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.categorySeparatorView.set(height: Theme.borderHeight)
        self.categorySeparatorView.topAnchor.constraint(equalTo: self.reputationView.bottomAnchor, constant: marginVertical).isActive = true
        self.categorySeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.categorySeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.categoryTitleLabel.set(height: height)
        self.categoryTitleLabel.topAnchor.constraint(equalTo: self.categorySeparatorView.bottomAnchor, constant: marginVertical).isActive = true
        self.categoryTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.categoryTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.categoryContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.categoryContentLabel.topAnchor.constraint(equalTo: self.categoryTitleLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.categoryContentLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.categoryContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.categoryContentLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -marginVertical).isActive = true
    }

    func displayQRCode() {
        let controller = QRCodeController(string: User.current!.address)
        self.present(controller, animated: true)
    }

    func updateButton() {
        let isContactAdded = Yap.sharedInstance.containsObject(for: self.app.address, in: TokenContact.collectionKey)
        let fontColor = isContactAdded ? Theme.tintColor : Theme.darkTextColor
        let title = isContactAdded ? "✓ Added" : "Add app"

        self.addContactButton.setAttributedTitle(NSAttributedString(string: title, attributes: [NSFontAttributeName: Theme.semibold(size: 13), NSForegroundColorAttributeName: fontColor]), for: .normal)
    }

    func updateReputation() {
        RatingsClient.shared.scores(for: self.app.address) { ratingScore in
            self.reputationView.setScore(ratingScore)
        }
    }

    func didTapMessageContactButton() {
        // create thread if needed
        TSStorageManager.shared().dbConnection.readWrite { transaction in
            var recipient = SignalRecipient(textSecureIdentifier: self.app.address, with: transaction)

            if recipient == nil {
                recipient = SignalRecipient(textSecureIdentifier: self.app.address, relay: nil, supportsVoice: false)
            }

            recipient?.save(with: transaction)
            let thread = TSContactThread.getOrCreateThread(withContactId: self.app.address, transaction: transaction)
            if thread.archivalDate() != nil {
                thread.unarchiveThread(with: transaction)
            }
        }

        DispatchQueue.main.async {
            (self.tabBarController as? TabBarController)?.displayMessage(forAddress: self.app.address)
        }
    }

    func didTapAddContactButton() {
        if Yap.sharedInstance.containsObject(for: self.app.address, in: TokenContact.collectionKey) {
            Yap.sharedInstance.removeObject(for: self.app.address, in: TokenContact.collectionKey)

            TSStorageManager.shared().dbConnection.readWrite { transaction in
                let thread = TSContactThread.getOrCreateThread(withContactId: self.app.address, transaction: transaction)
                thread.archiveThread(with: transaction)
            }

            self.updateButton()
        } else {
            Yap.sharedInstance.insert(object: self.app.JSONData, for: self.app.address, in: TokenContact.collectionKey)
            SoundPlayer.playSound(type: .addedContact)
            self.updateButton()
        }
    }
}
