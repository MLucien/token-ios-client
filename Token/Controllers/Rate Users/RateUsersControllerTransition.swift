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

enum ControllerTransitionOperation: Int {
    case present
    case dismiss
}

class RateUserControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let operation: ControllerTransitionOperation

    var duration: TimeInterval {
        switch operation {
        case .present: return 0.8
        case .dismiss: return 0.4
        }
    }

    init(operation: ControllerTransitionOperation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch self.operation {
        case .present: self.present(with: transitionContext)
        case .dismiss: self.dismiss(with: transitionContext)
        }
    }

    func present(with context: UIViewControllerContextTransitioning) {
        guard let controller = context.viewController(forKey: UITransitionContextViewControllerKey.to) as? RateUserController else { return }
        controller.contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        controller.contentView.alpha = 0.5

        UIView.animate(withDuration: self.duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .easeOut, animations: {
            controller.contentView.alpha = 1
        }) { didComplete in
            context.completeTransition(didComplete)
        }

        UIView.animate(withDuration: self.duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 20, options: .easeOut, animations: {
            controller.contentView.transform = .identity
        }, completion: nil)
    }

    func dismiss(with context: UIViewControllerContextTransitioning) {
        guard let controller = context.viewController(forKey: UITransitionContextViewControllerKey.from) as? RateUserController else { return }

        UIView.animate(withDuration: self.duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeIn, animations: {
            controller.contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            controller.contentView.alpha = 0
        }) { didComplete in
            context.completeTransition(didComplete)
        }
    }
}
