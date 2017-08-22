//
//  LikeModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Like {
   static let ref = Database.database().reference(withPath: "MainDataBase")
   
   static func add(_ newLike: LikeItem,
                   completion: @escaping (_ isSucceded: Bool) -> Void) {
      // add like id for user feedback implementation
      var like = newLike
      let likeRef = ref.child("/userslikes/" + newLike.userId + "/onposts/" + newLike.postId).childByAutoId()
      like.key = likeRef.key
      
      var updates: [String: Any?] = [
         "/userslikes/" + like.userId + "/onposts/" + like.postId: like.toAnyObject(),
         "/postslikes/" + like.postId + "/"         + like.userId: like.toAnyObject()
      ]
      
      if like.userId != like.postAddedByUserId { // dont add your own likes
         var likeForFeedBack = like.toAnyObject()
         likeForFeedBack["isViewed"] = false // when user will open feedback -> true
         updates.updateValue(likeForFeedBack, forKey: "/feedback/" + like.postAddedByUserId + "/" + like.key)
      }
      
      // update likes count
      let refToPostLikesCountInfo = ref.child("postsLikesAndCommentsCountInfo/" + like.postId + "/counting/likesCount")
      refToPostLikesCountInfo.observeSingleEvent(of: .value, with: { snapshot in
         var likesCount = 0
         
         if let countOfLikes = snapshot.value as? Int {
            likesCount = countOfLikes
         }
         
         updates.updateValue(likesCount + 1, forKey: "postsLikesAndCommentsCountInfo/" + like.postId + "/counting/likesCount")
         // also add short like info
         updates.updateValue(true, forKey: "postsLikesAndCommentsCountInfo/" + like.postId + "/likes/" + like.userId)
         
         ref.updateChildValues(updates, withCompletionBlock: { error, _ in
            if error != nil {
               if error!.localizedDescription == "Permission denied" { // this can only be with concurent data
                  // client need to resend request. Idk, how to do it from code actually. Will try 2 fix it
                  // in the future
                  completion(false)
               }
            } else {
               completion(true)
            }
         })
      })
   }
   
   static func remove(with userId: String, _ post: PostItem,
                      completion: @escaping (_ isSucceded: Bool) -> Void) {
      var updates: [String: Any?] = [
         "/userslikes/" + userId   + "/onposts/" + post.key: nil,
         "/postslikes/" + post.key + "/"         + userId:   nil
      ]
      
      // deleting from feedback node
      getLikeFromUser(id: userId, postId: post.key) { likeItem in
         guard let like = likeItem else {
            completion(false)
            return
         }
         
         if like.userId != like.postAddedByUserId {
            updates.updateValue(nil, forKey: "/feedback/" + like.postAddedByUserId + "/" + like.key)
         }
         
         // update likes count
         let refToPostLikesCountInfo = ref.child("postsLikesAndCommentsCountInfo/" + like.postId + "/counting/likesCount")
         refToPostLikesCountInfo.observeSingleEvent(of: .value, with: { snapshot in
            var likesCount = 0
            
            if let countOfLikes = snapshot.value as? Int {
               likesCount = countOfLikes
            }
            
            updates.updateValue(likesCount - 1, forKey: "postsLikesAndCommentsCountInfo/" + like.postId + "/counting/likesCount")
            // also add short like info
            updates.updateValue(nil, forKey: "postsLikesAndCommentsCountInfo/" + like.postId + "/likes/" + like.userId)
            
            ref.updateChildValues(updates, withCompletionBlock: { error, _ in
               if error != nil {
                  if error!.localizedDescription == "Permission denied" { // this can only be with concurent data
                     // client need to resend request. Idk, how to do it from code actually. Will try 2 fix it
                     // in the future
                     completion(false)
                  }
               } else {
                  completion(true)
               }
            })
         })
      }
   }
   
   static func getLikeFromUser(id: String, postId: String,
                               completion: @escaping (_ likeId: LikeItem?) -> Void) {
      let refToLike = ref.child("/userslikes/" + id + "/onposts/" + postId)
      
      refToLike.observeSingleEvent(of: .value, with: { snapshot in
         if snapshot.exists() {
            let like = LikeItem(snapshot: snapshot)
            
            completion(like)
         } else {
            completion(nil)
         }
      })
   }
   
   static func isLikedByUser(_ postId: String,
                             completion: @escaping (_ isLiked: Bool) -> Void) {
      let currentUserId = UserModel.getCurrentUserId()
      
      let refToPostLikeByUser = Database.database().reference(withPath: "MainDataBase/userslikes").child(currentUserId)
         .child("onposts").child(postId)
      refToPostLikeByUser.observeSingleEvent(of: .value, with: { snapshot in
         if let _ = snapshot.value as? [String: Any] {
            completion(true)
         } else {
            completion(false)
         }
      })
   }
}
