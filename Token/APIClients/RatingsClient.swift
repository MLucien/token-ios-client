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
import Teapot
import SweetFoundation

struct RatingScore {
    struct StarsCount {
        static var zero: StarsCount {
            return StarsCount(one: 0, two: 0, three: 0, four: 0, five: 0)
        }

        let one: Int
        let two: Int
        let three: Int
        let four: Int
        let five: Int

        init?(_ json: [String: Int]) {
            guard let one = json["1"] else { return nil }
            guard let two = json["2"] else { return nil }
            guard let three = json["3"] else { return nil }
            guard let four = json["4"] else { return nil }
            guard let five = json["5"] else { return nil }

            self.init(one: one, two: two, three: three, four: four, five: five)
        }

        private init(one: Int, two: Int, three: Int, four: Int, five: Int) {
            self.one = one
            self.two = two
            self.three = three
            self.four = four
            self.five = five
        }
    }

    static var zero: RatingScore {
        return RatingScore(score: 0.0, count: 0, stars: StarsCount.zero)
    }

    let score: Double
    let count: Int

    let stars: StarsCount

    init?(json: [String: Any]) {
        guard let score = json["score"] as? Double else { return nil }
        guard let count = json["count"] as? Int else { return nil }
        guard let stars = json["stars"] as? [String: Int] else { return nil }
        guard let starsCount = StarsCount(stars) else { return nil }

        self.init(score: score, count: count, stars: starsCount)
    }

    private init(score: Double, count: Int, stars: StarsCount) {
        self.score = score
        self.count = count
        self.stars = stars
    }
}

class RatingsClient: NSObject {
    public static let shared: RatingsClient = RatingsClient()

    public var teapot: Teapot

    public var baseURL: URL

    private override init() {
        self.baseURL = URL(string: TokenRatingsServiceBaseURLPath)!
        self.teapot = Teapot(baseURL: self.baseURL)

        super.init()
    }

    private func fetchTimestamp(_ completion: @escaping ((_ ratingScore: Int) -> Void)) {
        self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { fatalError() }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                completion(timestamp)
            case .failure(_, let response, _):
                print(response)
                fatalError()
            }
        }
    }

    public func submit(userId: String, rating: Int, review: String) {
        self.fetchTimestamp { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/review/submit"
            let payload: [String: Any] = [
                "rating": rating,
                "reviewee": userId,
                "review": review,
            ]

            let payloadData = try! JSONSerialization.data(withJSONObject: payload, options: [])
            let payloadString = String(data: payloadData, encoding: .utf8)!
            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(describing: timestamp)]
            let json = RequestParameter(payload)

            self.teapot.post(path, parameters: json, headerFields: fields) { result in
                switch result {
                case .success:
                    let alert = UIAlertController(title: "Success", message: "User succesfully reviewed.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))

                    UIApplication.shared.delegate!.window!?.rootViewController!.present(alert, animated: true)
                case .failure(let json, _, _):
                    guard let json = json?.dictionary, let errors = json["errors"] as? [Any], let error = errors.first as? [String: Any], let message = error["message"] as? String else { return }

                    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))

                    UIApplication.shared.delegate!.window!?.rootViewController!.present(alert, animated: true)
                }
            }
        }
    }

    public func scores(for userId: String, completion: @escaping ((_ ratingScore: RatingScore) -> Void)) {
        self.teapot.get("/v1/user/\(userId)") { result in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { return }
                guard let ratingScore = RatingScore(json: json) else { return }

                completion(ratingScore)
            case .failure:
                completion(RatingScore.zero)
            }
        }
    }
}
