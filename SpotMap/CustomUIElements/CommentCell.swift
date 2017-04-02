//
//  CommentCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class CommentCell: UICollectionViewCell {
    static let font = UIFont(name: "OCRAStd", size: 14)!
    static let inset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    static func cellSize(width: CGFloat, text: String) -> CGSize {
        return TextSize.size(text, font: CommentCell.font, width: width, insets: CommentCell.inset).size
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.font = CommentCell.font
        label.textColor = UIColor.white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = UIEdgeInsetsInsetRect(bounds, CommentCell.inset)
    }
}
