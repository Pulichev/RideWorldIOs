//
//  CommentsModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 11.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import FirebaseDatabase

class CommentsModel {
    // Function for loading comments for certain post
    static func loadCommentsForPost(postId: String, completion: @escaping (_ loadedComments: [CommentItem]) -> Void) {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(postId).child("comments")
        
        ref.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
            var newItems: [CommentItem] = []
            
            for item in snapshot.children {
                let commentItem = CommentItem(snapshot: item as! FIRDataSnapshot)
                newItems.append(commentItem)
            }
            newItems = newItems.sorted(by: { $0.commentId < $1.commentId })
            completion(newItems)
        })
    }
}
