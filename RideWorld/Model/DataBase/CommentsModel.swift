//
//  CommentsModel.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct Comment {
   static var refToSpotPostsNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost")
   
   // Function for loading comments for certain post
   static func loadList(for postId: String,
                            completion: @escaping (_ loadedComments: [CommentItem]) -> Void) {
      let ref = refToSpotPostsNode.child(postId).child("comments")
      
      ref.queryOrdered(byChild: "key").observeSingleEvent(of: .value, with: { snapshot in
         var newItems: [CommentItem] = []
         
         for item in snapshot.children {
            let commentItem = CommentItem(snapshot: item as! FIRDataSnapshot)
            newItems.append(commentItem)
         }
         
         newItems = newItems.sorted(by: { $0.commentId < $1.commentId })
         completion(newItems)
      })
   }
   
   static func add(for postId: String, withText text: String?,
                             completion: @escaping (_ loadedComments: CommentItem) -> Void) {
      let refForNewComment = refToSpotPostsNode.child(postId).child("comments").childByAutoId()
      
      let currentUserId = User.getCurrentUserId()
      let currentDateTime = String(describing: Date())
      let newComment = CommentItem(refForNewComment.key, currentUserId, postId, text!, currentDateTime)
      
      refForNewComment.setValue(newComment.toAnyObject())
      
      completion(newComment)
   }
   
   static func delete(with id: String, from postId: String) {
      let refToComment = refToSpotPostsNode.child(postId).child("comments").child(id)
      
      refToComment.removeValue()
   }
}
