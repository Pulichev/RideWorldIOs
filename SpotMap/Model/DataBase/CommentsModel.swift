//
//  CommentsModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth

class CommentsModel {
    static var refToSpotPostsNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost")
    
    // Function for loading comments for certain post
    static func loadCommentsForPost(postId: String,
                                    completion: @escaping (_ loadedComments: [CommentItem]) -> Void) {
        let ref = self.refToSpotPostsNode.child(postId).child("comments")
        
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
    
    static func addNewComment(postId: String, text: String?,
                              completion: @escaping (_ loadedComments: CommentItem) -> Void) {
        let refForNewComment = self.refToSpotPostsNode.child(postId).child("comments").childByAutoId()
        
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let currentDateTime = String(describing: Date())
        let newComment = CommentItem(commentId: refForNewComment.key, userId: currentUserId!, postId: postId, commentary: text!, datetime: currentDateTime)
        
        refForNewComment.setValue(newComment.toAnyObject())
        
        completion(newComment)
    }
}
