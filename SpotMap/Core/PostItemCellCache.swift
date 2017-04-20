//
//  PostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import ActiveLabel

class PostItemCellCache {
   var key: String!
   var post: PostItem!
   var userInfo: UserItem!
   var userNickName = String()
   var postDate = String()
   var postTime = String()
   var postDescription = String()
   var isPhoto = Bool()
   var isLikedPhoto = UIImageView()
   var postIsLiked = Bool()
   var likesCount = Int()
   var isCached = false
   
   init(spotPost: PostItem, stripController: PostsStripController) {
      self.key = spotPost.key
      self.post = spotPost
      initializeUser()
      let sourceDate = post.createdDate
      // formatting date to yyyy-mm-dd
      let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
      self.postDate = finalDate
      let finalTime = sourceDate[sourceDate.index(sourceDate.startIndex, offsetBy: 11)..<sourceDate.index(sourceDate.startIndex, offsetBy: 16)]
      self.postTime = finalTime
      self.postDescription = post.description
      self.isPhoto = post.isPhoto
      self.userLikedThisPost(stripController: stripController)
      self.countPostLikes(stripController: stripController)
   }
   
   func initializeUser() {
      User.getItemById(for: post.addedByUser,
                       completion: { userItem in
                        self.userInfo = userItem
                        self.userNickName = self.userInfo.login
      })
   }
   
   func userLikedThisPost(stripController: PostsStripController) {
      Post.isLikedByUser(post.key,
                         completion: { isLiked in
                           if isLiked {
                              self.postIsLiked = true
                              self.isLikedPhoto.image = UIImage(named: "respectActive.png")
                           } else {
                              self.postIsLiked = false
                              self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
                           }
                           
                           stripController.tableView.reloadData()
      })
   }
   
   func countPostLikes(stripController: PostsStripController) {
      Post.getLikesCount(for: post.key,
                         completion: { countOfPostLikes in
                           self.likesCount = countOfPostLikes
                           stripController.tableView.reloadData()
                           
      })
   }
   
   func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
      if (!self.postIsLiked) {
         self.postIsLiked = true
         self.isLikedPhoto.image = UIImage(named: "respectActive.png")
         self.likesCount += 1
      } else {
         self.postIsLiked = false
         self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
         self.likesCount -= 1
      }
   }
}
