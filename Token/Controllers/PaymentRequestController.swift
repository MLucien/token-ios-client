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

protocol PaymentRequestControllerDelegate: class {
    func paymentRequestControllerDidFinish(valueInWei: NSDecimalNumber?)
}

class PaymentRequestController: PaymentController {
    weak var delegate: PaymentRequestControllerDelegate?

    lazy var continueBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(sendRequest))

        return item
    }()

    lazy var cancelBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelRequest))

        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let title = UIBarButtonItem(title: "Request Payment", style: .plain, target: nil, action: nil)
        title.setTitleTextAttributes([NSFontAttributeName: Theme.semibold(size: 17)], for: .normal)

        self.toolbar.items = [self.cancelBarButton, spacing, title, spacing, self.continueBarButton]
    }

    func cancelRequest() {
        self.delegate?.paymentRequestControllerDidFinish(valueInWei: nil)
    }

    func sendRequest() {
        self.delegate?.paymentRequestControllerDidFinish(valueInWei: self.valueInWei)
    }
}
