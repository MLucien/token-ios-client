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
import Teapot

public class EthereumAPIClient: NSObject {

    static let shared: EthereumAPIClient = EthereumAPIClient()

    private static let collectionKey = "ethereumExchangeRate"

    public var teapot: Teapot

    private var exchangeTeapot: Teapot

    public var exchangeRate: Decimal {
        self.updateRate()

        if let rate = Yap.sharedInstance.retrieveObject(for: EthereumAPIClient.collectionKey) as? Decimal {
            return rate
        } else {
            return 15.0
        }
    }

    private override init() {
        self.teapot = Teapot(baseURL: URL(string: TokenEthereumServiceBaseURLPath)!)
        self.exchangeTeapot = Teapot(baseURL: URL(string: "https://api.coinbase.com")!)

        super.init()

        self.updateRate()
    }

    private func updateRate() {
        self.getRate { rate in
            Yap.sharedInstance.insert(object: rate, for: EthereumAPIClient.collectionKey)
        }
    }

    func timestamp(_ completion: @escaping ((_ timestamp: String) -> Void)) {
        self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { fatalError() }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                completion(String(timestamp))
            case .failure(_, _, let error):
                print(error)
            }
        }
    }

    func getRate(_ completion: @escaping ((_ rate: Decimal) -> Void)) {
        self.exchangeTeapot.get("/v2/exchange-rates?currency=ETH") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { fatalError() }
                guard let data = json["data"] as? [String: Any] else { fatalError() }
                guard let rates = data["rates"] as? [String: Any] else { fatalError() }
                guard let usd = rates["USD"] as? String else { fatalError() }

                completion(Decimal(Double(usd)!))
            case .failure(_, let response, let error):
                print(response)
                fatalError(error.localizedDescription)
            }
        }
    }

    public func createUnsignedTransaction(to address: String, value: NSDecimalNumber, completion: @escaping ((_ unsignedTransaction: String?, _ error: Error?) -> Void)) {
        let parameters: [String: Any] = [
            "from": Cereal.shared.paymentAddress,
            "to": address,
            "value": value.toHexString,
        ]

        let json = RequestParameter(parameters)

        self.teapot.post("/v1/tx/skel", parameters: json) { result in
            switch result {
            case .success(let json, let response):
                print(response)
                completion(json!.dictionary!["tx"] as? String, nil)
            case .failure(let json, let response, let error):
                print(response)
                print(json ?? "")
                print(error)
                completion(nil, error)
            }
        }
    }

    public func sendSignedTransaction(originalTransaction: String, transactionSignature: String, completion: @escaping ((_ json: RequestParameter?, _ error: Error?) -> Void)) {
        self.timestamp { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/tx"
            let params = [
                "tx": originalTransaction,
                "signature": transactionSignature,
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = cereal.sha3WithWallet(string: payloadString)

            let signature = "0x\(cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headers: [String: String] = [
                "Token-ID-Address": cereal.paymentAddress,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = RequestParameter(params)

            self.teapot.post(path, parameters: json, headerFields: headers) { result in
                switch result {
                case .success(let json, let response):
                    print(response)
                    print(json ?? "")
                    completion(json, nil)
                case .failure(let json, let response, let error):
                    print(response)
                    print(json ?? "")
                    print(error)
                    let json = RequestParameter((json!.dictionary!["errors"] as! [[String: Any]]).first!)
                    completion(json, error)
                }
            }
        }
    }

    public func getBalance(address: String, completion: @escaping ((_ balance: NSDecimalNumber, _ error: Error?) -> Void)) {
        self.teapot.get("/v1/balance/\(address)") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey : "Could not fetch balance."])
                guard response.statusCode == 200 else { completion(0, error); return }
                guard let json = json?.dictionary else { completion(0, error); return }

                let unconfirmedBalanceString = json["unconfirmed_balance"] as? String ?? "0"
                let unconfirmedBalance = NSDecimalNumber(hexadecimalString: unconfirmedBalanceString)

                User.current?.balance = unconfirmedBalance

                completion(unconfirmedBalance, nil)
            case .failure(let json, let response, let error):
                completion(0, error)
                print(error)
                print(response)
                print(json ?? "")
            }
        }
    }

    public func registerForPushNotifications(deviceToken: String) {
        self.timestamp { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/apn/register"
            let address = cereal.paymentAddress

            let params = ["registration_id": deviceToken]
            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = cereal.sha3WithWallet(string: payloadString)
            let signature = "0x\(cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = RequestParameter(params)
            self.teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                }
            }
        }
    }

    public func registerForNotifications(_ completion: @escaping ((_ success: Bool) -> Void)) {
        self.timestamp { timestamp in
            let cereal = Cereal.shared
            let address = User.current!.paymentAddress
            let path = "/v1/register"
            let params = [
                "addresses": [
                    address,
                ],
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = cereal.sha3WithWallet(string: payloadString)
            let signature = "0x\(cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = RequestParameter(params)

            self.teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)
                    completion(true)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                    completion(false)
                }
            }
        }
    }

    public func deregisterForNotifications() {
        self.timestamp { timestamp in
            let cereal = Cereal.shared
            let address = cereal.paymentAddress
            let path = "/v1/deregister"

            let params = [
                "addresses": [
                    address,
                ],
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = cereal.sha3WithWallet(string: payloadString)
            let signature = "0x\(cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headerFields: [String: String] = [
                "Token-ID-Address": address,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp,
            ]

            let json = RequestParameter(params)

            self.teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                }
            }
        }
    }
}
