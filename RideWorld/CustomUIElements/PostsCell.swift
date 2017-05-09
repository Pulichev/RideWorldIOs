//
//  PostsCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ActiveLabel

class PostsCell: UITableViewCell {
   var post: PostItem! {
      didSet {
         openComments.setTitle("Open commentaries (\(post.commentsCount!))", for: .normal)
      }
   }
   var userInfo: UserItem! // user, who posted
   
   @IBOutlet var spotPostMedia: UIView!
   var player: AVPlayer!
   
   @IBOutlet weak var postDate: UILabel!
   @IBOutlet weak var userNickName: UIButton!
   @IBOutlet weak var postDescription: ActiveLabel! {
      didSet {
         postDescription.numberOfLines = 0
         postDescription.enabledTypes = [.mention, .hashtag, .url]
         postDescription.textColor = .black
         postDescription.mentionColor = .brown
         postDescription.hashtagColor = .purple
         postDescription.handleHashtagTap { hashtag in }
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
      
      if(!postIsLiked) {
         postIsLiked = true
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! + 1)
         addNewLike()
      } else {
         postIsLiked = false
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! - 1)
         removeExistedLike()
      }
   }
   
   func addNewLike() {
      // init new like
      let currentUserId = User.getCurrentUserId()
      let likePlacedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: post.key, postWasAddedBy: post.addedByUser, at: likePlacedTime)
      
      Like.add(newLike)
   }
   
   func removeExistedLike() {
      let currentUserId = User.getCurrentUserId()
      
      Like.remove(with: currentUserId, post)
   }
}
