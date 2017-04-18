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

import Foundation
import EtherealCereal
import HDWallet

/// An EtherealCereal wrapper. Generates the address and public key for a given private key. Signs messages.
public class Cereal: NSObject {

    static var shared: Cereal = Cereal()

    let entropyByteCount = 16

    var idCereal: EtherealCereal

    var walletCereal: EtherealCereal

    var mnemonic: BTCMnemonic

    private static let collectionKey = "cerealPrivateKey"

    public var address: String {
        return self.idCereal.address
    }

    public var paymentAddress: String {
        return self.walletCereal.address
    }

    // restore from words
    public init?(words: [String]) {
        guard let mnemonic = BTCMnemonic(words: words, password: nil, wordListType: .english) else { return nil }
        self.mnemonic = mnemonic

        Yap.sharedInstance.insert(object: self.mnemonic.words.joined(separator: " "), for: Cereal.collectionKey)

        // ID path 0H/1/0
        let idKeychain = self.mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 1).derivedKeychain(at: 0)
        let idPrivateKey = idKeychain.key.privateKey.hexadecimalString()
        self.idCereal = EtherealCereal(privateKey: idPrivateKey)

        // wallet path: 0H/0/0
        let walletKeychain = self.mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 0).derivedKeychain(at: 0)
        let walletPrivateKey = walletKeychain.key.privateKey.hexadecimalString()
        self.walletCereal = EtherealCereal(privateKey: walletPrivateKey)
    }

    // restore from local user or create new
    public override init() {
        if let words = Yap.sharedInstance.retrieveObject(for: Cereal.collectionKey) as? String {
            self.mnemonic = BTCMnemonic(words: words.components(separatedBy: " "), password: nil, wordListType: .english)!
        } else {
            var entropy = Data(count: self.entropyByteCount)
            // This creates the private key inside a block, result is of internal type ResultType.
            // We just need to check if it's 0 to ensure that there were no errors.
            let result = entropy.withUnsafeMutableBytes { mutableBytes in
                SecRandomCopyBytes(kSecRandomDefault, entropy.count, mutableBytes)
            }
            guard result == 0 else { fatalError("Failed to randomly generate and copy bytes for entropy generation. SecRandomCopyBytes error code: (\(result)).") }

            self.mnemonic = BTCMnemonic(entropy: entropy, password: nil, wordListType: .english)!

            Yap.sharedInstance.insert(object: self.mnemonic.words.joined(separator: " "), for: Cereal.collectionKey)
        }

        // ID path 0H/1/0
        let idKeychain = self.mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 1).derivedKeychain(at: 0)
        let idPrivateKey = idKeychain.key.privateKey.hexadecimalString()
        self.idCereal = EtherealCereal(privateKey: idPrivateKey)

        // wallet path: 0H/0/0
        let walletKeychain = self.mnemonic.keychain.derivedKeychain(at: 0, hardened: true).derivedKeychain(at: 0).derivedKeychain(at: 0)
        let walletPrivateKey = walletKeychain.key.privateKey.hexadecimalString()
        self.walletCereal = EtherealCereal(privateKey: walletPrivateKey)
    }

    // MARK: - Sign with id

    public func signWithID(message: String) -> String {
        return self.idCereal.sign(message: message)
    }

    public func signWithID(hex: String) -> String {
        return self.idCereal.sign(hex: hex)
    }

    public func sha3WithID(string: String) -> String {
        return self.idCereal.sha3(string: string)
    }

    public func sha3WithID(data: Data) -> String {
        return self.idCereal.sha3(data: data)
    }

    // MARK: - Sign with wallet

    public func signWithWallet(message: String) -> String {
        return self.walletCereal.sign(message: message)
    }

    public func signWithWallet(hex: String) -> String {
        return self.walletCereal.sign(hex: hex)
    }

    public func sha3WithWallet(string: String) -> String {
        return self.walletCereal.sha3(string: string)
    }
}
