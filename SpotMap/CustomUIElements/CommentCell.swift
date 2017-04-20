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
   @IBOutlet weak var commentText: ActiveLabel!
   @IBOutlet weak var date: UILabel!
   
   var comment: CommentItem! {
      didSet {
         self.commentText.text = self.comment.commentary
         let sourceDate = self.comment.datetime
         // Formatting date to yyyy-mm-dd
         let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 16)]
         self.date.text = finalDate
         self.initialiseUserPhoto()
         self.initialiseUserButton()
         self.initializeCommentText()
      }
   }
   
   func initialiseUserPhoto() {
      self.userPhoto.image = UIImage(named: "grayRec.jpg")
      
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
   
   func initializeCommentText() {
      self.commentText.numberOfLines = 0
      self.commentText.enabledTypes = [.mention, .hashtag, .url]
      self.commentText.textColor = .black
      self.commentText.mentionColor = .brown
      self.commentText.hashtagColor = .purple
   }
}
