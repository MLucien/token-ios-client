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

public class ChatsNavigationController: UINavigationController {

    let selectedThreadAddressKey = "SelectedThread"

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.tabBarItem = UITabBarItem(title: "Chats", image: #imageLiteral(resourceName: "messages"), tag: 0)
        self.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: move restoration to the tabbar controller, so we only restore the currently selected.
        if let address = UserDefaults.standard.string(forKey: self.selectedThreadAddressKey) {
            // we delay by one cycle and it's enough for UIKit to set the children viewcontrollers
            // for the navigation controller. Otherwise `viewcontrollers` will be nil and it wont restore.
            // Downside: it blinks the previous view for no.
            // TODO: move all of this the the navigator so we can restore the hiararchy straight from the app delegate.
            DispatchQueue.main.asyncAfter(seconds: 0.0) {
                self.openThread(withAddress: address)
            }
        }
    }

    public func openThread(withAddress address: String) {
        _ = self.popToRootViewController(animated: false)
        guard let chatsController = self.viewControllers.first as? ChatsController else { fatalError() }

        let thread = chatsController.thread(withAddress: address)
        let messagesController = ChatController(thread: thread, chatAPIClient: chatsController.chatAPIClient)

        self.pushViewController(messagesController, animated: false)
    }

    public func openThread(withThreadIdentifier identifier: String, animated: Bool) {
        _ = self.popToRootViewController(animated: animated)
        guard let chatsController = self.viewControllers.first as? ChatsController else { fatalError() }
        guard let thread = chatsController.thread(withIdentifier: identifier) else { return }

        let messagesController = ChatController(thread: thread, chatAPIClient: chatsController.chatAPIClient)
        self.pushViewController(messagesController, animated: animated)
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? ChatController {
            UserDefaults.standard.setValue(viewController.thread.contactIdentifier(), forKey: self.selectedThreadAddressKey)
        }
    }

    public override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaults.standard.removeObject(forKey: self.selectedThreadAddressKey)
        return super.popViewController(animated: animated)
    }

    public override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaults.standard.removeObject(forKey: self.selectedThreadAddressKey)
        return super.popToRootViewController(animated: animated)
    }

    public override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaults.standard.removeObject(forKey: self.selectedThreadAddressKey)
        return super.popToViewController(viewController, animated: animated)
    }
}
