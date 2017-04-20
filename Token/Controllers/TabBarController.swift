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
import UserNotifications
import CameraScanner

let TabBarItemTitleOffset: CGFloat = -3.0

open class TabBarController: UITabBarController {

    public enum Tab {
        case browsing
        case messaging
        case scanner
        case favorites
        case me
    }

    let tabBarSelectedIndexKey = "TabBarSelectedIndex"

    public var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    public var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    internal lazy var scannerController: ScannerViewController = {
        let controller = ScannerViewController(instructions: "Scan a user profile QR code", types: [.qrCode])
        controller.delegate = self

        return controller
    }()

    internal lazy var placeholderScannerController: UIViewController = {
        let controller = UIViewController()
        controller.tabBarItem = UITabBarItem(title: "Scan", image: UIImage(), tag: 0)

        return controller
    }()

    internal lazy var scanContactButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(didTapScanContactButton))

        return item
    }()


    internal var browseController: BrowseNavigationController!
    internal var messagingController: ChatsNavigationController!
//    internal var appsController: AppsNavigationController!
    internal var contactsController: ContactsNavigationController!
    internal var settingsController: SettingsNavigationController!

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.delegate = self
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Refactor all this navigation controllers subclasses into one, they have similar code
        self.browseController = BrowseNavigationController(rootViewController: BrowseController())
        self.messagingController = ChatsNavigationController(rootViewController: ChatsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))

        self.contactsController = ContactsNavigationController(rootViewController: ContactsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.settingsController = SettingsNavigationController(rootViewController: SettingsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))

        self.viewControllers = [
            self.browseController,
            self.messagingController,
            self.placeholderScannerController,
            self.contactsController,
            self.settingsController,
        ]

        self.view.tintColor = Theme.tintColor

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.tabBar.barTintColor = Theme.viewBackgroundColor
        self.tabBar.unselectedItemTintColor = Theme.unselectedItemTintColor

        let index = UserDefaults.standard.integer(forKey: self.tabBarSelectedIndexKey)
        self.selectedIndex = index
    }

    public func displayMessage(forAddress address: String) {
        self.selectedIndex = self.viewControllers!.index(of: self.messagingController)!

        self.messagingController.openThread(withAddress: address)
    }

    public func `switch`(to tab: Tab) {
        switch tab {
        case .browsing:
            self.selectedIndex = 0
        case .messaging:
            self.selectedIndex = 1
        case .scanner:
            self.selectedIndex = 2
        case .favorites:
            self.selectedIndex = 3
        case .me:
            self.selectedIndex = 4
        }
    }

    func didTapScanContactButton() {
        /*
         _ = self.scannerController.view
         self.scannerController.toolbar.setItems([self.scannerController.cancelItem], animated: true)
         self.present(self.scannerController, animated: true)
         */
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController == self.placeholderScannerController {
            SoundPlayer.playSound(type: .menuButton)
            self.present(self.scannerController, animated: true)

            return false
        }

        return true
    }

    public func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        SoundPlayer.playSound(type: .menuButton)

        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets

        if let index = self.viewControllers?.index(of: viewController) {
            UserDefaults.standard.set(index, forKey: self.tabBarSelectedIndexKey)
        }
    }
}

extension TabBarController: ScannerViewControllerDelegate {

    public func scannerViewControllerDidCancel(_: ScannerViewController) {
        self.dismiss(animated: true)
    }

    public func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {
        let username = result.replacingOccurrences(of: QRCodeController.addUsernameBasePath, with: "")
        let contactName = TokenContact.name(from: username)
        self.idAPIClient.findContact(name: contactName) { contact in
            guard let contact = contact else {
                controller.startScanning()

                return
            }

            SoundPlayer.playSound(type: .scanned)

            self.dismiss(animated: true) {
                let contactController = ContactController(contact: contact, idAPIClient: self.idAPIClient)

                self.navigationController?.pushViewController(contactController, animated: true)
            }
        }
    }
}
