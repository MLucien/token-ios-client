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
import SweetFoundation

public final class Theme: NSObject {}

extension Theme {
    public static var borderHeight: CGFloat {
        return 1.0 / UIScreen.main.scale
    }
}

extension Theme {
    public static var randomColor: UIColor {
        let colors = [UIColor.lightGray, UIColor.green, UIColor.red, UIColor.magenta, UIColor.purple, UIColor.blue, UIColor.yellow]

        return colors[Int(arc4random_uniform(UInt32(colors.count)))]
    }

    public static var lightTextColor: UIColor {
        return .white
    }

    public static var darkTextColor: UIColor {
        return UIColor(hex: "161621")
    }

    public static var greyTextColor: UIColor {
        return UIColor(hex: "A4A4AB")
    }

    public static var lightGreyTextColor: UIColor {
        return UIColor(hex: "9E9E9E")
    }

    public static var lighterGreyTextColor: UIColor {
        return UIColor(hex: "F3F3F3")
    }

    public static var tintColor: UIColor {
        return UIColor(hex: "01C236")
    }

    public static var viewBackgroundColor: UIColor {
        return .white
    }

    public static var unselectedItemTintColor: UIColor {
        return UIColor(hex: "B1B4B8")
    }

    public static var messageViewBackgroundColor: UIColor {
        return UIColor(hex: "F3F3F3")
    }

    public static var backupPhraseBackgroundColor: UIColor {
        return UIColor(hex: "F6F6F6")
    }

    public static var settingsBackgroundColor: UIColor {
        return UIColor(hex: "FCFCFC")
    }

    public static var inputFieldBackgroundColor: UIColor {
        return UIColor(hex: "FAFAFA")
    }

    public static var navigationTitleTextColor: UIColor {
        return .white
    }

    public static var borderColor: UIColor {
        return UIColor(hex: "D7DBDC")
    }

    public static var actionButtonTitleColor: UIColor {
        return UIColor(hex: "0BBEE3")
    }

    public static var outgoingMessageBackgroundColor: UIColor {
        return UIColor(hex: "00C1E7")
    }

    public static var incomingMessageBackgroundColor: UIColor {
        return .white
    }

    public static var ratingBackground: UIColor {
        return UIColor(hex: "D1D1D1")
    }

    public static var ratingTint: UIColor {
        return UIColor(hex: "EB6E00")
    }

    public static var outgoingMessageTextColor: UIColor {
        return self.lightTextColor
    }

    public static var incomingMessageTextColor: UIColor {
        return UIColor(hex: "4A4A57")
    }

    public static var errorColor: UIColor {
        return UIColor(hex: "FF0000")
    }
}

extension Theme {

    static func light(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Light", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightLight)
    }

    static func regular(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Regular", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightRegular)
    }

    static func semibold(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Semibold", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightSemibold)
    }

    static func bold(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Bold", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightBold)
    }

    static func medium(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Medium", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightBold)
    }
}
