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
      let likeRef = ref.child("/users/" + newLike.userId + "/likePlaced/onposts/" + newLike.postId).childByAutoId()
      like.key = likeRef.key
      
      let updates: [String: Any?] = [
         "/users/" + like.userId + "/likePlaced/onposts/" + like.postId: like.toAnyObject(),
         "/spotpost/" + like.postId + "/likes/" + like.userId: like.toAnyObject(),
         "/feedback/" + like.postAddedByUserId + "/" + like.key: like.toAnyObject()
      ]
      
      ref.updateChildValues(updates)
   }
   
   static func remove(with userId: String, _ post: PostItem) {
      var updates: [String: Any?] = [
         "/users/" + userId + "/likePlaced/onposts/" + post.key: nil,
         "/spotpost/" + post.key + "/likes/" + userId: nil
      ]
      
      // deleting from feedback node
      getLikeFromUser(id: userId, postId: post.key) { like in
         updates.updateValue(nil, forKey: "/feedback/" + like.postAddedByUserId + "/" + like.key)
         
         ref.updateChildValues(updates)
      }
   }
   
   static func getLikeFromUser(id: String, postId: String,
                               completion: @escaping (_ likeId: LikeItem) -> Void) {
      let refToLike = ref.child("/users/" + id + "/likePlaced/onposts/" + postId)
      
      refToLike.observeSingleEvent(of: .value, with: { snapshot in
         let like = LikeItem(snapshot: snapshot)
         
         completion(like)
      })
   }
}
