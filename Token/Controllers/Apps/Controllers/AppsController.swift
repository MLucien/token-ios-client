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

class AppsController: UIViewController {
    static let cellHeight = CGFloat(220)
    static let cellWidth = CGFloat(90)

    lazy var latestTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = "Latest"
        label.font = Theme.regular(size: 14)
        label.textColor = Theme.greyTextColor

        return label
    }()

    lazy var recommendedTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = "Recommended"
        label.font = Theme.regular(size: 14)
        label.textColor = Theme.greyTextColor

        return label
    }()

    lazy var recommendedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: AppsController.cellWidth, height: AppsController.cellHeight)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        layout.minimumLineSpacing = 15

        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false

        return view
    }()

    lazy var searchResultsView: SearchResultsView = {
        let view = SearchResultsView(withAutoLayout: true)
        view.selectionDelegate = self

        return view
    }()

    fileprivate lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.delegate = self

        searchController.searchBar.sizeToFit()
        searchController.searchBar.tintColor = Theme.tintColor
        searchController.searchBar.delegate = self

        return searchController
    }()

    lazy var containerView: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    var recommendedApps = [TokenContact]() {
        didSet {
            self.recommendedCollectionView.reloadData()
        }
    }

    var appsAPIClient: AppsAPIClient

    init(appsAPIClient: AppsAPIClient = .shared) {
        self.appsAPIClient = appsAPIClient

        super.init(nibName: nil, bundle: nil)

        self.loadViewIfNeeded()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Browse"

        self.view.addSubview(self.searchResultsView)
        self.searchResultsView.fillSuperview()
        self.searchResultsView.isHidden = true

        self.view.addSubview(self.containerView)
        self.containerView.fillSuperview()

        let separatorView = UIView(withAutoLayout: true)
        separatorView.backgroundColor = UIColor.gray

        self.containerView.addSubview(separatorView)
        self.containerView.addSubview(self.recommendedCollectionView)
        self.containerView.addSubview(self.recommendedTitleLabel)

        self.recommendedCollectionView.backgroundColor = Theme.viewBackgroundColor
        self.recommendedCollectionView.dataSource = self
        self.recommendedCollectionView.delegate = self
        self.recommendedCollectionView.register(AppCell.self)

        self.recommendedTitleLabel.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 20).isActive = true
        self.recommendedTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15).isActive = true
        self.recommendedTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15).isActive = true

        self.recommendedCollectionView.topAnchor.constraint(equalTo: self.recommendedTitleLabel.bottomAnchor, constant: 20).isActive = true
        self.recommendedCollectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.recommendedCollectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.recommendedCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: AppsController.cellHeight).isActive = true

        separatorView.topAnchor.constraint(equalTo: self.recommendedCollectionView.bottomAnchor, constant: -15).isActive = true
        separatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15).isActive = true
        separatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15).isActive = true

        self.navigationItem.titleView = self.searchController.searchBar

        self.appsAPIClient.getFeaturedApps { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.recommendedApps = apps
        }
    }

    func showSearchResultsView(shouldShow: Bool) {
        self.containerView.isHidden = shouldShow
        self.searchResultsView.isHidden = !shouldShow
    }

    func reload(searchText: String) {
        self.appsAPIClient.search(searchText) { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.searchResultsView.results = apps
        }
    }
}

extension AppsController: UICollectionViewDataSource {

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return self.recommendedApps.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(AppCell.self, for: indexPath)

        let app = self.recommendedApps[indexPath.row]
        cell.app = app

        return cell
    }
}

extension AppsController: UICollectionViewDelegate {

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let app = self.recommendedApps[indexPath.row]
        let appController = AppController(app: app)
        self.navigationController?.pushViewController(appController, animated: true)
    }
}

extension AppsController: UISearchBarDelegate {

    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        if searchText.length == 0 {
            self.searchResultsView.results = [TokenContact]()
        }
        self.showSearchResultsView(shouldShow: searchText.length > 0)

        // Throttles search to delay performing a search while the user is typing.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload(searchText:)), object: searchText)
        self.perform(#selector(reload(searchText:)), with: searchText, afterDelay: 0.5)
    }
}

extension AppsController: UISearchControllerDelegate {

    func didDismissSearchController(_: UISearchController) {
        self.showSearchResultsView(shouldShow: false)
    }
}

extension AppsController: SearchResultsViewDelegate {

    func searchResultsView(_: SearchResultsView, didTapApp app: TokenContact) {
        let appController = AppController(app: app)
        self.navigationController?.pushViewController(appController, animated: true)
    }
}
