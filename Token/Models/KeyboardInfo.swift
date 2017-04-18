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

public struct KeyboardInfo {
    public let beginFrame: CGRect
    public let endFrame: CGRect
    public let animationCurve: UIViewAnimationCurve
    public let animationDuration: TimeInterval

    public var animationOptions: UIViewAnimationOptions {
        switch animationCurve {
        case .easeInOut: return .curveEaseInOut
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .linear: return .curveLinear
        }
    }

    init(_ info: [AnyHashable: Any]?) {
        self.beginFrame = (info?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        self.endFrame = (info?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        self.animationCurve = UIViewAnimationCurve(rawValue: info?[UIKeyboardAnimationCurveUserInfoKey] as? Int ?? 0) ?? .easeInOut
        self.animationDuration = TimeInterval(info?[UIKeyboardAnimationDurationUserInfoKey] as? Double ?? 0.0)
    }
}
