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

public class Navigator: NSObject {
    private let navigator = Navigator()

    // Navigation assumes the following structure:
    // TabBar controller contains a messages controller. Messages controller lists chats, and pushes threads.
    public static func navigate(to threadIdentifier: String, animated: Bool) {
        // make sure we don't do UI stuff in a background thread
        DispatchQueue.main.async {
            // get tab controller
            guard let tabController = UIApplication.shared.delegate?.window??.rootViewController as? TabBarController else { return }

            tabController.switch(to: .messaging)
            _ = tabController.messagingController.popToRootViewController(animated: animated)
            tabController.messagingController.openThread(withThreadIdentifier: threadIdentifier, animated: animated)
        }
    }
}
