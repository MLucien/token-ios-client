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

let TabBarItemTitleOffset: CGFloat = -3.0

open class TabBarController: UITabBarController {

    public enum Tab {
        case home
        case messaging
        case apps
        case contacts
        case settings
    }

    let tabBarSelectedIndexKey = "TabBarSelectedIndex"

    public var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    public var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    internal var homeController: HomeNavigationController!
    internal var messagingController: MessagingNavigationController!
    internal var appsController: AppsNavigationController!
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
        self.homeController = HomeNavigationController(rootViewController: HomeController())
        self.messagingController = MessagingNavigationController(rootViewController: ChatsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.appsController = AppsNavigationController(rootViewController: AppsController())
        self.contactsController = ContactsNavigationController(rootViewController: ContactsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))
        self.settingsController = SettingsNavigationController(rootViewController: SettingsController(idAPIClient: self.idAPIClient, chatAPIClient: self.chatAPIClient))

        self.viewControllers = [
            self.homeController,
            self.messagingController,
            self.appsController,
            self.contactsController,
            self.settingsController,
        ]

        self.view.tintColor = Theme.tintColor

        self.view.backgroundColor = Theme.viewBackgroundColor
        self.tabBar.barTintColor = Theme.viewBackgroundColor

        let index = UserDefaults.standard.integer(forKey: self.tabBarSelectedIndexKey)
        self.selectedIndex = index
    }

    public func displayMessage(forAddress address: String) {
        self.selectedIndex = self.viewControllers!.index(of: self.messagingController)!

        self.messagingController.openThread(withAddress: address)
    }

    public func `switch`(to tab: Tab) {
        switch tab {
        case .home:
            self.selectedIndex = 0
        case .messaging:
            self.selectedIndex = 1
        case .apps:
            self.selectedIndex = 2
        case .contacts:
            self.selectedIndex = 3
        case .settings:
            self.selectedIndex = 4
        }
    }
}

extension TabBarController: UITabBarControllerDelegate {

    public func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        SoundPlayer.playSound(type: .menuButton)

        self.automaticallyAdjustsScrollViewInsets = viewController.automaticallyAdjustsScrollViewInsets

        if let index = self.viewControllers?.index(of: viewController) {
            UserDefaults.standard.set(index, forKey: self.tabBarSelectedIndexKey)
        }
    }
}
