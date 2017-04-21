//
//  CommentCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel

class CommentCell: UITableViewCell {
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userNickName: UIButton!
   @IBOutlet weak var commentText: ActiveLabel! {
      didSet {
         commentText.numberOfLines = 0
         commentText.enabledTypes = [.mention, .hashtag, .url]
         commentText.textColor = .black
         commentText.mentionColor = .brown
         commentText.hashtagColor = .purple
      }
   }
   @IBOutlet weak var date: UILabel!
   
   var comment: CommentItem! {
      didSet {
         commentText.text = comment.commentary
         let sourceDate = comment.datetime
         // Formatting date to yyyy-mm-dd
         let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 16)]
         date.text = finalDate
         initialiseUserPhoto()
         initialiseUserButton()
      }
   }
   
   func initialiseUserPhoto() {
      userPhoto.image = UIImage(named: "grayRec.jpg")
      
      UserMedia.getURL(for: comment.userId, withSize: 90,
                       completion: { URL in
                        self.userPhoto.kf.setImage(with: URL) // Using kf for caching images.
      })
   }
   
   func initialiseUserButton() {
      User.getItemById(for: comment.userId,
                       completion: { userItem in
                        self.userNickName.setTitle(userItem.login, for: .normal)
      })
   }
}
