//
//  CommentCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class CommentCell: UITableViewCell {
    static let font = UIFont(name: "Helvetica", size: 14)!
    static let inset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var userNickName: UIButton!
    @IBOutlet weak var commentText: UITextView!
    
    static func cellSize(width: CGFloat, text: String) -> CGSize {
        return TextSize.size(text, font: CommentCell.font, width: width, insets: CommentCell.inset).size
    }
    
    var comment: CommentItem! {
        didSet {
            self.userNickName.setTitle("ololo", for: .normal)
            self.commentText.text = self.comment.commentary
            self.initialiseUserPhoto()
        }
    }
    
    func initialiseUserPhoto() {
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/userMainPhotoURLs/" + self.comment.userId + "_resolution90x90.jpeg"
        let riderPhotoURL = storage.reference(forURL: url)
        
        riderPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                self.userPhoto.kf.setImage(with: URL) //Using kf for caching images.
                self.userPhoto.layer.cornerRadius = self.userPhoto.frame.size.height / 2
            }
        }
    }
}
