//
//  CommentCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 02.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel
import MGSwipeTableCell

class CommentCell: MGSwipeTableCell {
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
         // Formatting date to yyyy-mm-dd
         date.text = DateTimeParser.getDateTime(from: comment.datetime)
         initialiseUserPhoto()
         initialiseUserButton()
      }
   }
   
   func initialiseUserPhoto() {
      userPhoto.image = UIImage(named: "grayRec.jpg")
      
      User.getItemById(for: comment.userId) { user in
         if user.photo90ref != nil {
            self.userPhoto.kf.setImage(with: URL(string: user.photo90ref!)) // Using kf for caching images.
         }
      }
   }
   
   func initialiseUserButton() {
      User.getItemById(for: comment.userId) { userItem in
         self.userNickName.setTitle(userItem.login, for: .normal)
      }
   }
}
