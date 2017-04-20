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

public class FavoritesNavigationController: UINavigationController {

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.tabBarItem = UITabBarItem(title: "Favorites", image: #imageLiteral(resourceName: "contacts"), tag: 1)
        self.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
}
