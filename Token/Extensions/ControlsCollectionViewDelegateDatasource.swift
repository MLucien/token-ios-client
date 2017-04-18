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

protocol ControlViewActionDelegate: class {
    func controlsCollectionViewDidSelectControl(_ button: SofaMessage.Button)
}

class SubcontrolsViewDelegateDatasource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateRightAlignedLayout, ControlCellDelegate {
    var items: [SofaMessage.Button] = [] {
        didSet {
            self.subcontrolsCollectionView?.isUserInteractionEnabled = true
        }
    }

    var subcontrolsCollectionView: UICollectionView?

    weak var actionDelegate: ControlViewActionDelegate?

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return self.items.count
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return self.items.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SubcontrolCell = collectionView.dequeue(SubcontrolCell.self, for: indexPath)
        cell.buttonItem = self.items[indexPath.row]
        cell.delegate = self

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 44)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 0
    }

    func didTapButton(for cell: ControlCell) {
        guard let indexPath = self.subcontrolsCollectionView?.indexPath(for: cell) else { return }
        //        let normalizedIndexPath = self.reversedControlIndexPath(indexPath)

        self.actionDelegate?.controlsCollectionViewDidSelectControl(self.items[indexPath.row])
    }

    func reversedControlIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row = (self.items.count - 1) - indexPath.item
        return IndexPath(row: row, section: indexPath.section)
    }
}

class ControlsViewDelegateDatasource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateRightAlignedLayout, ControlCellDelegate {
    var items: [SofaMessage.Button] = [] {
        didSet {
            self.controlsCollectionView?.isUserInteractionEnabled = true
        }
    }

    var controlsCollectionView: ControlsCollectionView?

    weak var actionDelegate: ControlViewActionDelegate?

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return self.items.count
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return self.items.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ControlCell = collectionView.dequeue(ControlCell.self, for: indexPath)
        cell.buttonItem = self.items[indexPath.row]
        cell.delegate = self

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = ControlCell(frame: .zero)
        cell.buttonItem = self.items[indexPath.row]

        let size = cell.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: 38))

        return size
    }

    func didTapButton(for cell: ControlCell) {
        guard let indexPath = self.controlsCollectionView?.indexPath(for: cell) else { return }
        self.actionDelegate?.controlsCollectionViewDidSelectControl(self.items[indexPath.row])
    }

    func reversedControlIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row = (self.items.count - 1) - indexPath.item
        return IndexPath(row: row, section: indexPath.section)
    }
}
