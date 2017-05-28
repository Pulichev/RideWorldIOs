//
//  PostModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 15.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Post {
   static var refToPostsNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost")
   
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
      let refToPostLikes = refToPostsNode.child(postId).child("likes")
      
      // catch if user liked this post
      refToPostLikes.observeSingleEvent(of: .value, with: { snapshot in
         let likesCountInt = snapshot.children.allObjects.count
         completion(likesCountInt)
      })
   }
   
   static func isLikedByUser(_ postId: String,
                             completion: @escaping (_ isLiked: Bool) -> Void) {
      let currentUserId = User.getCurrentUserId()
      
      let refToCurrentUserLikeOnPost = refToPostsNode.child(postId).child("likes").child(currentUserId)
      
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
      let mainReference = FIRDatabase.database().reference(withPath: "MainDataBase")
      
      let updates = [
         "/spotpost/" + postItem.key: postItem.toAnyObject(),
         "/spots/" + postItem.spotId + "/posts/" + postItem.key: true,
         "/users/" + postItem.addedByUser + "/posts/" + postItem.key: true
      ]
      
      mainReference.updateChildValues(updates,
                                      withCompletionBlock: { (error, _) in
                                       if error == nil {
                                          completion(true)
                                       } else {
                                          completion(false)
                                       }
      })
   }
   
   // we dont need escaping here. User will not wait,
   // while post is deleting. Like async. But with media,
   // some garbage can remain
   static func remove(_ postItem: PostItem) {
      let mainReference = FIRDatabase.database().reference(withPath: "MainDataBase")
      
      let updates: [String: Any?] = [
         "/spotpost/" + postItem.key: nil,
         "/spots/" + postItem.spotId + "/posts/" + postItem.key: nil,
         "/users/" + postItem.addedByUser + "/posts/" + postItem.key: nil
      ]
      
      mainReference.updateChildValues(updates)
   }
   
   static func delete(with postId: String) {
      let refToPostNode = refToPostsNode.child(postId)
      refToPostNode.removeValue()
   }
}
