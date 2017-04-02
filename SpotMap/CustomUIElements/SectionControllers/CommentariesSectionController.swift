//
//  CommentariesSectionController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import IGListKit

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
        return 2
    }
    
    func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext, let entry = entry else { return .zero }
        let width = context.containerSize.width
        
        if index == 0 {
            return CGSize(width: width, height: 30)
        } else {
            return CommentCell.cellSize(width: width, text: entry.commentary)
        }
    }
    
    func cellForItem(at index: Int) -> UICollectionViewCell {
        let cellClass: AnyClass = CommentCell.self
        let cell = collectionContext!.dequeueReusableCell(of: cellClass, for: self, at: index)
        
        let commentCell = cell as? CommentCell
        commentCell?.label.text = entry.commentary
        
        return cell
    }
    
    func didUpdate(to object: Any) {
        entry = object as? CommentItem
    }
    
    func didSelectItem(at index: Int) {}
}

