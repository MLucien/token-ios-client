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
import AudioToolbox

public struct SoundPlayer {

    enum SoundType: String {
        case messageSent
        case messageReceived
        case scanned = "scan"
        case addedContact = "addContactApp"
        case requestPayment
        case paymentSend
        case menuButton
    }

    static let shared = SoundPlayer()

    fileprivate var sounds = [SystemSoundID]()

    fileprivate init() {
        self.sounds = [
            self.soundID(for: .messageSent),
        ]
    }

    static func playSound(type: SoundType) {
        self.shared.playSound(type: type)
    }

    func soundID(for type: SoundType) -> SystemSoundID {
        var soundID: SystemSoundID = 0

        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "m4a") else { fatalError("Could not play sound!") }
        AudioServicesCreateSystemSoundID((url as NSURL), &soundID)

        return soundID
    }

    func playSound(type: SoundType) {
        guard UIApplication.shared.applicationState == .active else { return }

        let id = self.soundID(for: type)
        AudioServicesPlaySystemSound(id)
    }
}
