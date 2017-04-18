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

class TextLabel: UILabel {

    convenience init(_ text: String) {
        self.init(withAutoLayout: true)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.5
        paragraphStyle.paragraphSpacing = -4

        let attributes: [String: Any] = [
            NSFontAttributeName: Theme.regular(size: 16),
            NSForegroundColorAttributeName: Theme.greyTextColor,
            NSParagraphStyleAttributeName: paragraphStyle,
        ]

        self.attributedText = NSMutableAttributedString(string: text, attributes: attributes)
        self.numberOfLines = 0
    }
}
