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
import SweetSwift

struct EthereumConverter {

    static let forcedLocale = "en_US"

    public static let weisToEtherConstant = NSDecimalNumber(string: "1000000000000000000")

    public static var weisToEtherPowerOf10Constant: Int16 {
        return Int16(self.weisToEtherConstant.stringValue.length - 1)
    }

    public static func localFiatToEther(forFiat balance: NSNumber) -> NSDecimalNumber {
        let etherValue = balance.decimalValue / EthereumAPIClient.shared.exchangeRate

        return NSDecimalNumber(decimal: etherValue).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior)
    }

    public static func ethereumValueString(forEther balance: NSDecimalNumber) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 4
        numberFormatter.maximumFractionDigits = 4

        return "\(numberFormatter.string(from: balance)!) ETH"
    }

    public static func ethereumValueString(forWei balance: NSDecimalNumber) -> String {
        return self.ethereumValueString(forEther: balance.dividing(by: self.weisToEtherConstant).rounding(accordingToBehavior: NSDecimalNumber.weiRoundingBehavior))
    }

    public static func fiatValueString(forWei balance: NSDecimalNumber) -> String {
        let ether = balance.dividing(by: self.weisToEtherConstant)
        let currentFiatConversion = NSDecimalNumber(decimal: EthereumAPIClient.shared.exchangeRate)
        let fiat: NSDecimalNumber = ether.multiplying(by: currentFiatConversion)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: self.forcedLocale)

        return numberFormatter.string(from: fiat)!
    }

    public static func fiatValueStringWithCode(forWei balance: NSDecimalNumber) -> String {
        return "\(self.fiatValueString(forWei: balance)) \(Locale(identifier: self.forcedLocale).currencyCode!)"
    }

    public static func balanceAttributedString(forWei balance: NSDecimalNumber) -> NSAttributedString {
        let fiatText = self.fiatValueStringWithCode(forWei: balance)
        let etherText = self.ethereumValueString(forWei: balance)

        let fiatTextFull = fiatText + " · "
        let text = fiatTextFull + etherText
        let etherRange = (text as NSString).range(of: etherText)
        let fiatRange = (text as NSString).range(of: fiatTextFull)

        let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: Theme.regular(size: 15)])
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.greyTextColor, range: etherRange)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Theme.darkTextColor, range: fiatRange)

        return attributedString
    }
}
