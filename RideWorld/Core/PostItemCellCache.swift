//
//  PostsCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import ActiveLabel

class PostItemCellCache {
   var key: String!
   var post: PostItem!
   var postDate: String!
   var isLikedPhoto = UIImageView()
   var postIsLiked: Bool!
   var likesCount = Int()
   var commentsCount = Int()
   var isCached = false
   
   init(_ post: PostItem,
        completion: @escaping (_ cellCache: PostItemCellCache) -> Void) {
      key = post.key
      self.post = post
      // formatting date to yyyy-mm-dd
      postDate = DateTimeParser.getDateTime(from: post.createdDate)
      
      Post.getLikesAndCommentsCount(for: key) { (likesCount, commentsCount) in
         self.likesCount = likesCount
         self.commentsCount = commentsCount
         
         Like.isLikedByUser(self.key) { isLiked in
            self.initLikeData(isLiked)
            
            completion(self)
         }
      }
   }
   
   func initLikeData(_ isLiked: Bool) {
      if isLiked {
         self.postIsLiked = true
         self.isLikedPhoto.image = UIImage(named: "respectActive.png")
      } else {
         self.postIsLiked = false
         self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
      }
   }
   
   func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
      if (!postIsLiked) {
         postIsLiked = true
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         likesCount += 1
      } else {
         postIsLiked = false
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         likesCount -= 1
      }
   }
}
