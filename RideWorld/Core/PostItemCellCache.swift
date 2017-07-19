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
   var isLikedPhoto = UIImageView() // need to fix it.
   var postIsLiked: Bool!
   var likesCount = Int()
   var isCached = false
   
   init(_ post: PostItem, completion: @escaping (_ cellCache: PostItemCellCache) -> Void) {
      key = post.key
      self.post = post
      // formatting date to yyyy-mm-dd
      postDate = DateTimeParser.getDateTime(from: post.createdDate)
      likesCount = post.likesCount
      self.userLikedThisPost() {
         completion(self)
      }
   }
   
   func userLikedThisPost(completion: @escaping () -> Void) {
      Post.isLikedByUser(post.key) { isLiked in
         if isLiked {
            self.postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
         } else {
            self.postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
         }
         
         completion()
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
