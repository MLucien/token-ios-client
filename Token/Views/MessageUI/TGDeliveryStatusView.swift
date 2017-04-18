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

class TGDeliveryStatusView: UIView {

    override var tintColor: UIColor! {
        didSet {
            self.checkmark1ImageView.tintColor = self.tintColor
            self.checkmark2ImageView.tintColor = self.tintColor
            self.clockView.tintColor = self.tintColor
        }
    }

    var clockView = TGClockProgressView()
    var checkmark1ImageView = UIImageView(image: Constant.checkmark1Image)
    var checkmark2ImageView = UIImageView(image: Constant.checkmark2Image)

    var deliveryStatus: TSOutgoingMessageState = .attemptingOut {
        didSet {
            self.updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(clockView)
        addSubview(checkmark1ImageView)
        addSubview(checkmark2ImageView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clockView.frame = bounds
        checkmark1ImageView.frame = CGRect(x: 0, y: 2, width: 12, height: 11)
        checkmark2ImageView.frame = CGRect(x: 3, y: 2, width: 12, height: 11)
    }

    private func updateUI() {
        switch self.deliveryStatus {
        case .attemptingOut:
            self.clockView.isHidden = false
            self.clockView.startAnimating()
            self.checkmark1ImageView.isHidden = true
            self.checkmark2ImageView.isHidden = true
        case .sent:
            self.clockView.stopAnimating()
            self.clockView.isHidden = true
            self.checkmark1ImageView.isHidden = false
            self.checkmark2ImageView.isHidden = true
        case .delivered:
            self.clockView.stopAnimating()
            self.clockView.isHidden = true
            self.checkmark1ImageView.isHidden = false
            self.checkmark2ImageView.isHidden = false
        default:
            self.clockView.stopAnimating()
            self.clockView.isHidden = true
            self.checkmark1ImageView.isHidden = true
            self.checkmark2ImageView.isHidden = true
        }
    }

    struct Constant {
        static let checkmark1Image = #imageLiteral(resourceName: "TGMessageCheckmark1").withRenderingMode(.alwaysTemplate)
        static let checkmark2Image = #imageLiteral(resourceName: "TGMessageCheckmark2").withRenderingMode(.alwaysTemplate)
    }
}
