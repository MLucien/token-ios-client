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

class HomeController: UIViewController {
    var appsAPIClient: AppsAPIClient
    var ethereumAPIClient: EthereumAPIClient

    var apps = [TokenContact]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alwaysBounceVertical = true
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = Theme.viewBackgroundColor

        view.register(HomeItemCell.self)

        return view
    }()

    lazy var containerView: HomeContainerView = {
        let view = HomeContainerView(withAutoLayout: true)

        return view
    }()

    init(appsAPIClient: AppsAPIClient = .shared, ethererumAPIClient: EthereumAPIClient = .shared) {
        self.appsAPIClient = appsAPIClient
        self.ethereumAPIClient = ethererumAPIClient

        super.init(nibName: nil, bundle: nil)

        self.fetchAndUpdateBalance()
        self.loadViewIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"

        self.view.backgroundColor = Theme.borderColor

        self.view.addSubview(self.containerView)
        self.view.addSubview(self.collectionView)

        self.containerView.set(height: 115)
        self.containerView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.containerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.containerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        // TODO: adjust insets for full content
        self.collectionView.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 0)
        self.collectionView.topAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 12).isActive = true
        self.collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        self.appsAPIClient.getFeaturedApps { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.apps = apps
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.fetchAndUpdateBalance()
    }

    func fetchAndUpdateBalance() {
        guard let user = User.current else {
            self.containerView.balance = NSDecimalNumber.zero

            return
        }

        self.ethereumAPIClient.getBalance(address: user.paymentAddress) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.containerView.balance = balance
            }
        }
    }

    func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        self.containerView.balance = balance
    }
}

extension HomeController: UICollectionViewDataSource {

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return self.apps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(HomeItemCell.self, for: indexPath)
        let app = self.apps[indexPath.row]
        cell.app = app

        return cell
    }
}

extension HomeController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 12
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 12
    }
}

extension HomeController: UICollectionViewDelegate {

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let app = self.apps[indexPath.row]
        let appController = AppController(app: app)
        self.navigationController?.pushViewController(appController, animated: true)
    }
}
