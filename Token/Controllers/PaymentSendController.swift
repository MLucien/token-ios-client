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

protocol PaymentSendControllerDelegate: class {
    func paymentSendControllerDidFinish(valueInWei: NSDecimalNumber?)
}

class PaymentSendController: PaymentController {
    weak var delegate: PaymentSendControllerDelegate?

    lazy var continueBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(send))

        return item
    }()

    lazy var cancelBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let title = UIBarButtonItem(title: "Send Payment", style: .plain, target: nil, action: nil)
        title.setTitleTextAttributes([NSFontAttributeName: Theme.semibold(size: 17)], for: .normal)

        self.toolbar.items = [self.cancelBarButton, spacing, title, spacing, self.continueBarButton]
    }

    func cancel() {
        self.delegate?.paymentSendControllerDidFinish(valueInWei: nil)
    }

    func send() {
        self.delegate?.paymentSendControllerDidFinish(valueInWei: self.valueInWei)
    }
}
