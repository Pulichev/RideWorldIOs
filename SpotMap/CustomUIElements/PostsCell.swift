//
//  PostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ActiveLabel

class PostsCell: UITableViewCell {
   var post: PostItem!
   var userInfo: UserItem! // user, who posted
   
   @IBOutlet var spotPostMedia: UIView!
   var player: AVPlayer!
   
   @IBOutlet weak var postDate: UILabel!
   @IBOutlet weak var postTime: UILabel!
   @IBOutlet weak var userNickName: UIButton!
   @IBOutlet weak var postDescription: ActiveLabel! {
      didSet {
         self.postDescription.numberOfLines = 0
         self.postDescription.enabledTypes = [.mention, .hashtag, .url]
         self.postDescription.textColor = .black
         self.postDescription.mentionColor = .brown
         self.postDescription.hashtagColor = .purple
         self.postDescription.handleHashtagTap { hashtag in }
      }
   }
   @IBOutlet weak var isLikedPhoto: UIImageView!
   @IBOutlet weak var likesCount: UILabel!
   @IBOutlet weak var openComments: UIButton!
   var isPhoto: Bool!
   var postIsLiked: Bool!
   
   var userLikedOrDeletedLike = false //using this to update cache if user liked or disliked post
   
   func addDoubleTapGestureOnPostPhotos() {
      //adding method on spot main photo tap
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:))) //target was only self
      tap.numberOfTapsRequired = 2
      spotPostMedia.addGestureRecognizer(tap)
      spotPostMedia.isUserInteractionEnabled = true
   }
   
   func postLiked(_ sender: Any) {
      if (userLikedOrDeletedLike) { // it might be a situation when user liked and disliked posts with out scroll.
         userLikedOrDeletedLike = false
      } else {
         userLikedOrDeletedLike = true
      }
      
      if(!self.postIsLiked) {
         self.postIsLiked = true
         self.isLikedPhoto.image = UIImage(named: "respectActive.png")
         let countOfLikesInt = Int(self.likesCount.text!)
         self.likesCount.text = String(countOfLikesInt! + 1)
         addNewLike()
      } else {
         self.postIsLiked = false
         self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
         let countOfLikesInt = Int(self.likesCount.text!)
         self.likesCount.text = String(countOfLikesInt! - 1)
         removeExistedLike()
      }
   }
   
   func addNewLike() {
      // init new like
      let currentUserId = User.getCurrentUserId()
      let likePlacedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: self.post.key, at: likePlacedTime)
      
      Like.addToUserNode(newLike)
      Like.addToPostNode(newLike)
   }
   
   func removeExistedLike() {
      let currentUserId = User.getCurrentUserId()
      
      Like.removeFromUserNode(with: currentUserId, post)
      Like.removeFromPostNode(with: currentUserId, post)
   }
}
