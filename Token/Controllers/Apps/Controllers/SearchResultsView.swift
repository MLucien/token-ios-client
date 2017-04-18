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

protocol SearchResultsViewDelegate: class {
    func searchResultsView(_ searchResultsView: SearchResultsView, didTapApp app: TokenContact)
}

class SearchResultsView: UITableView {
    weak var selectionDelegate: SearchResultsViewDelegate?

    var results = [TokenContact]() {
        didSet {
            self.reloadData()
        }
    }

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)

        self.dataSource = self
        self.delegate = self
        self.separatorStyle = .none

        self.register(SearchResultCell.self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchResultsView: UITableViewDataSource {

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return self.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(SearchResultCell.self, for: indexPath)
        let app = self.results[indexPath.row]
        cell.app = app

        return cell
    }
}

extension SearchResultsView: UITableViewDelegate {

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let app = self.results[indexPath.row]

        self.selectionDelegate?.searchResultsView(self, didTapApp: app)
    }
}
