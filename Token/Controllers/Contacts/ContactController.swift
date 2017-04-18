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
import CoreImage

public class ContactController: UIViewController {
    var idAPIClient: IDAPIClient

    public var contact: TokenContact

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    lazy var qrCode: UIImage = {
        let image = UIImage.imageQRCode(for: self.contact.address, resizeRate: 0.8)
        let filter = CIFilter(name: "CIMaskToAlpha")!

        filter.setDefaults()
        filter.setValue(CIImage(cgImage: image.cgImage!), forKey: "inputImage")

        let cImage = filter.outputImage!

        return UIImage(ciImage: cImage)
    }()

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.textAlignment = .center
        view.font = Theme.bold(size: 20)

        return view
    }()

    lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.textAlignment = .center
        view.font = Theme.bold(size: 14)
        view.textColor = Theme.greyTextColor

        return view
    }()

    lazy var addContactButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setAttributedTitle(NSAttributedString(string: "Add contact", attributes: [NSFontAttributeName: Theme.semibold(size: 13)]), for: .normal)
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
        view.layer.borderWidth = Theme.borderHeight

        return view
    }()

    lazy var aboutSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var aboutTitleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.text = "About"
        view.textColor = .lightGray
        view.font = .systemFont(ofSize: 15)

        return view
    }()

    lazy var aboutContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)

        return view
    }()

    lazy var locationSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var locationTitleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.text = "Location"
        view.textColor = Theme.darkTextColor
        view.textColor = .lightGray
        view.font = .systemFont(ofSize: 15)

        return view
    }()

    lazy var locationContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)

        return view
    }()

    private init() {
        fatalError()
    }

    public init(contact: TokenContact, idAPIClient: IDAPIClient) {
        self.contact = contact
        self.idAPIClient = idAPIClient

        super.init(nibName: nil, bundle: nil)

        self.edgesForExtendedLayout = .bottom
        self.title = "Contact"
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
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.contact.displayName.length > 0 {
            self.nameLabel.text = self.contact.displayName
            self.usernameLabel.text = self.contact.username
        } else {
            self.usernameLabel.text = nil
            self.nameLabel.text = self.contact.username
        }

        self.aboutContentLabel.text = self.contact.about
        self.locationContentLabel.text = self.contact.location
        self.avatarImageView.image = self.contact.avatar

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: self.qrCode, style: .plain, target: self, action: #selector(ProfileController.displayQRCode))

        self.updateButton()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func addSubviewsAndConstraints() {
        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.usernameLabel)
        self.view.addSubview(self.addContactButton)
        self.view.addSubview(self.messageContactButton)

        self.view.addSubview(self.aboutSeparatorView)
        self.view.addSubview(self.aboutTitleLabel)
        self.view.addSubview(self.aboutContentLabel)

        self.view.addSubview(self.locationSeparatorView)
        self.view.addSubview(self.locationTitleLabel)
        self.view.addSubview(self.locationContentLabel)

        let height: CGFloat = 38.0
        let marginHorizontal: CGFloat = 20.0
        let marginVertical: CGFloat = 16.0
        let avatarSize: CGFloat = 166

        self.avatarImageView.set(height: avatarSize)
        self.avatarImageView.set(width: avatarSize)
        self.avatarImageView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 26).isActive = true
        self.avatarImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.avatarImageView.cornerRadius = avatarSize / 2

        self.nameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        self.nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        self.nameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: marginVertical).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.messageContactButton.set(height: height)
        self.messageContactButton.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.messageContactButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.messageContactButton.rightAnchor.constraint(equalTo: self.addContactButton.leftAnchor, constant: -marginHorizontal).isActive = true

        self.messageContactButton.widthAnchor.constraint(equalTo: self.addContactButton.widthAnchor).isActive = true

        self.addContactButton.set(height: height)
        self.addContactButton.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.addContactButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        // We set the view and separator width cosntraints to be the same, to force the scrollview content size to conform to the window
        // otherwise no view is requiring a width of the window, and the scrollview contentSize will shrink to the smallest
        // possible width that satisfy all other constraints.
        self.aboutSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.aboutSeparatorView.set(height: Theme.borderHeight)
        self.aboutSeparatorView.topAnchor.constraint(equalTo: self.addContactButton.bottomAnchor, constant: marginVertical).isActive = true
        self.aboutSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.aboutSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.aboutTitleLabel.set(height: 32)
        self.aboutTitleLabel.topAnchor.constraint(equalTo: self.aboutSeparatorView.bottomAnchor, constant: marginVertical).isActive = true
        self.aboutTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.aboutTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.aboutContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.aboutContentLabel.topAnchor.constraint(equalTo: self.aboutTitleLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.aboutContentLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.aboutContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.locationSeparatorView.set(height: Theme.borderHeight)
        self.locationSeparatorView.topAnchor.constraint(equalTo: self.aboutContentLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.locationSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.locationSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.locationTitleLabel.set(height: 32)
        self.locationTitleLabel.topAnchor.constraint(equalTo: self.locationSeparatorView.bottomAnchor, constant: marginVertical).isActive = true
        self.locationTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.locationTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.locationContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.locationContentLabel.topAnchor.constraint(equalTo: self.locationTitleLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.locationContentLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.locationContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.locationContentLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -marginVertical).isActive = true
    }

    func displayQRCode() {
        let controller = QRCodeController(string: self.contact.address)
        self.present(controller, animated: true)
    }

    func updateButton() {
        let isContactAdded = Yap.sharedInstance.containsObject(for: self.contact.address, in: TokenContact.collectionKey)
        let fontColor = isContactAdded ? Theme.tintColor : Theme.darkTextColor
        let title = isContactAdded ? "✓ Added" : "Add contact"

        self.addContactButton.setAttributedTitle(NSAttributedString(string: title, attributes: [NSFontAttributeName: Theme.semibold(size: 13), NSForegroundColorAttributeName: fontColor]), for: .normal)
    }

    func didTapMessageContactButton() {
        // create thread if needed
        TSStorageManager.shared().dbConnection.readWrite { transaction in
            var recipient = SignalRecipient(textSecureIdentifier: self.contact.address, with: transaction)

            if recipient == nil {
                recipient = SignalRecipient(textSecureIdentifier: self.contact.address, relay: nil, supportsVoice: false)
            }

            recipient?.save(with: transaction)
            let thread = TSContactThread.getOrCreateThread(withContactId: self.contact.address, transaction: transaction)
            if thread.archivalDate() != nil {
                thread.unarchiveThread(with: transaction)
            }
        }

        DispatchQueue.main.async {
            (self.tabBarController as? TabBarController)?.displayMessage(forAddress: self.contact.address)
        }
    }

    func didTapAddContactButton() {
        if Yap.sharedInstance.containsObject(for: self.contact.address, in: TokenContact.collectionKey) {
            Yap.sharedInstance.removeObject(for: self.contact.address, in: TokenContact.collectionKey)

            TSStorageManager.shared().dbConnection.readWrite { transaction in
                let thread = TSContactThread.getOrCreateThread(withContactId: self.contact.address, transaction: transaction)
                thread.archiveThread(with: transaction)
            }

            self.updateButton()
        } else {
            Yap.sharedInstance.insert(object: self.contact.JSONData, for: self.contact.address, in: TokenContact.collectionKey)
            SoundPlayer.playSound(type: .addedContact)
            self.updateButton()
        }
    }
}
