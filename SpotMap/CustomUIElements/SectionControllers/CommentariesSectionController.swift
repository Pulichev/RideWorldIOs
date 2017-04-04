//
//  CommentariesSectionController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import IGListKit
import FirebaseStorage

class CommentariesSectionController: IGListSectionController {
    var entry: CommentItem!
    
    override init() {
        super.init()
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
    }
}

// MARK: - IGListSectionType
extension CommentariesSectionController: IGListSectionType {
    func numberOfItems() -> Int {
        return 1
    }
    
    func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext, let entry = entry else { return .zero }
        let width = context.containerSize.width
        
        if index == 0 {
            return CommentCell.cellSize(width: width, text: entry.commentary)
        } else {
            return CommentCell.cellSize(width: width, text: entry.commentary)
        }
    }
    
    func cellForItem(at index: Int) -> UICollectionViewCell {
        let cellClass: AnyClass = CommentCell.self
        let cell = collectionContext!.dequeueReusableCell(of: cellClass, for: self, at: index)
        
        let commentCell = cell as? CommentCell
        commentCell?.label.text = entry.commentary
        self.initializeUserPhoto(cell: commentCell!)
        
        return cell
    }
    
    func didUpdate(to object: Any) {
        entry = object as? CommentItem
    }
    
    func didSelectItem(at index: Int) {}
    
    func initializeUserPhoto(cell: CommentCell) {
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.entry.userId + "_resolution90x90.jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                cell.userPhoto.kf.setImage(with: URL) //Using kf for caching images.
                cell.userPhoto.layer.cornerRadius = cell.userPhoto.frame.size.height / 2
            }
        }
    }
}

