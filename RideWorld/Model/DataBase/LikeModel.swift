//
//  LikeModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Like {
   static let ref = FIRDatabase.database().reference(withPath: "MainDataBase")
   
   static func add(_ newLike: LikeItem) {
      // add like id for user feedback implementation
      var like = newLike
      let likeRef = ref.child("/userslikes/" + newLike.userId + "/onposts/" + newLike.postId).childByAutoId()
      like.key = likeRef.key
      
      var updates: [String: Any?] = [
         "/userslikes/"    + like.userId + "/onposts/" + like.postId: like.toAnyObject(),
         "/posts/" + like.postId + "/likes/"              + like.userId: like.toAnyObject()
      ]
      
      if like.userId != like.postAddedByUserId { // dont add your own likes
         var likeForFeedBack = like.toAnyObject()
         likeForFeedBack["isViewed"] = false // when user will open feedback -> true
         updates.updateValue(likeForFeedBack, forKey: "/feedback/" + like.postAddedByUserId + "/" + like.key)
      }
      
      ref.updateChildValues(updates)
   }
   
   static func remove(with userId: String, _ post: PostItem) {
      var updates: [String: Any?] = [
         "/userslikes/"    + userId   + "/onposts/" + post.key: nil,
         "/posts/" + post.key + "/likes/"              + userId:   nil
      ]
      
      // deleting from feedback node
      getLikeFromUser(id: userId, postId: post.key) { like in
         if like.userId != like.postAddedByUserId {
            updates.updateValue(nil, forKey: "/feedback/" + like.postAddedByUserId + "/" + like.key)
         }
         
         ref.updateChildValues(updates)
      }
   }
   
   static func getLikeFromUser(id: String, postId: String,
                               completion: @escaping (_ likeId: LikeItem) -> Void) {
      let refToLike = ref.child("/userslikes/" + id + "/onposts/" + postId)
      
      refToLike.observeSingleEvent(of: .value, with: { snapshot in
         let like = LikeItem(snapshot: snapshot)
         
         completion(like)
      })
   }
}
