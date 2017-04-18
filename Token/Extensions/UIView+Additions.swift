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

extension UIViewAnimationOptions {

    static var easeIn: UIViewAnimationOptions {
        return [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction]
    }

    static var easeOut: UIViewAnimationOptions {
        return [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
    }
}

public extension UIView {

    static func highlightAnimation(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOut, animations: animations, completion: nil)
    }

    func bounce() {
        self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 200, options: .easeOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }

    func shake() {
        self.transform = CGAffineTransform(translationX: 10, y: 0)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 50, options: .easeOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}
