//
//  PostModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 15.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Post {
   static var refToMainDataBaseNode = Database.database().reference(withPath: "MainDataBase")
   static var refToPostsNode = refToMainDataBaseNode.child("posts")
   
   static func getItemById(for postId: String,
                           completion: @escaping (_ postItem: PostItem?) -> Void) {
      let refToPost = refToPostsNode.child(postId)
      
      refToPost.observeSingleEvent(of: .value, with: { snapshot in
         if snapshot.exists() {
            let postItem = PostItem(snapshot: snapshot)
            
            completion(postItem)
         } else {
            completion(nil)
         }
      })
   }
   
   static func getLikesCount(for postId: String,
                             completion: @escaping (_ likesCount: Int) -> Void) {
      let refToPostLikes = refToMainDataBaseNode.child("postslikes").child(postId)
      
      // catch if user liked this post
      refToPostLikes.observeSingleEvent(of: .value, with: { snapshot in
         let likesCountInt = snapshot.children.allObjects.count
         completion(likesCountInt)
      })
   }
   
   static func isLikedByUser(_ postId: String,
                             completion: @escaping (_ isLiked: Bool) -> Void) {
      let currentUserId = UserModel.getCurrentUserId()
      
      let refToCurrentUserLikeOnPost = refToMainDataBaseNode.child("userslikes").child(currentUserId).child("onposts").child(postId)
      
      refToCurrentUserLikeOnPost.observeSingleEvent(of: .value, with: { snapshot in
         if (snapshot.value as? [String : Any]) != nil {
            completion(true)
         } else {
            completion(false)
         }
      })
   }
   
   static func getNewPostId() -> String {
      return refToPostsNode.childByAutoId().key
   }
   
   static func add(_ postItem: PostItem,
                   completion: @escaping (_ hasFinished: Bool) -> Void) {
      let updates = [
         "/posts/" + postItem.key: postItem.toAnyObject(),
         "/spotsposts/" + postItem.spotId + "/" + postItem.key: postItem.toAnyObject(), // for post strip for spot
         "/usersposts/" + postItem.addedByUser + "/" + postItem.key: postItem.toAnyObject(), // for user profile
         "/userpostsfeed/" + postItem.addedByUser + "/" + postItem.key: postItem.toAnyObject() // for user posts feed
      ]
      
      refToMainDataBaseNode.updateChildValues(updates) { (error, _) in
         if error == nil {
            completion(true)
         } else {
            completion(false)
         }
      }
      // after adding new post to "/usersposts/" + postItem.addedByUser + "/" + postItem.key
      // cloud function will add this post to post strip of followers and userself
   }
   
   // we dont need escaping here. User will not wait,
   // while post is deleting. Like async. But with media,
   // some garbage can remain
   static func remove(_ postItem: PostItem) {
      let mainReference = Database.database().reference(withPath: "MainDataBase")
      
      let updates: [String: Any?] = [
         "/posts/" + postItem.key: nil,
         "/spotsposts/" + postItem.spotId + "/" + postItem.key: nil,
         "/usersposts/" + postItem.addedByUser + "/" + postItem.key: nil,
         "/userpostsfeed/" + postItem.addedByUser + "/" + postItem.key: nil
      ]
      
      mainReference.updateChildValues(updates)
      // after removing post from "/usersposts/" + postItem.addedByUser + "/" + postItem.key: nil
      // cloud function will delete this post from post strip of followers and userself
   }
   
   // MARK: - Likes and comments count
   static func getLikesAndCommentsCount(for postId: String,
                                        completion: @escaping (_ likesCount: Int, _ commentsCount: Int) -> Void) {
      let refToPostCounts = refToMainDataBaseNode.child("postsLikesAndCommentsCountInfo")
         .child(postId).child("counting")
      
      refToPostCounts.observeSingleEvent(of: .value, with: { snapshot in
         var commentsCount = 0
         var likesCount = 0
         
         if let countOfLikes = (snapshot.value as? [String: Any])?["likesCount"] as? Int {
            likesCount = countOfLikes
         }
         
         if let countOfComments = (snapshot.value as? [String: Any])?["commentsCount"] as? Int {
            commentsCount = countOfComments
         }
         
         completion(likesCount, commentsCount)
      })
   }
   
   static func getPostsCount(for userId: String,
                             completion: @escaping(_ postsCount: Int) -> Void) {
      var postsCount = 0
      
      let refToPostsCount = refToMainDataBaseNode.child("userpostscount").child(userId)
      
      refToPostsCount.observe(.value, with: { snapshot in
         if let countOfPosts = snapshot.value as? Int {
            postsCount = countOfPosts
         }
         
         completion(postsCount)
      })
   }
}
