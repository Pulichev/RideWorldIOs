//
//  CommentItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

class CommentItem: NSObject {
   let commentId: String
   let userId: String
   let postId: String
   let commentary: String // text of comment
   let datetime: String
   
   let ref: FIRDatabaseReference?
   
   init(_ commentId: String, _ userId: String, _ postId: String, _ commentary: String, _ datetime: String) {
      self.commentId = commentId
      self.userId = userId
      self.postId = postId
      self.commentary = commentary
      self.datetime = datetime
      
      self.ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      let snapshotValue = snapshot.value as! [String: AnyObject]
      userId = snapshotValue["userId"] as! String
      postId = snapshotValue["postId"] as! String
      commentary = snapshotValue["commentary"] as! String
      datetime = snapshotValue["datetime"] as! String
      commentId = snapshot.key
      
      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "commentId" : commentId,
         "userId" : userId,
         "postId" : postId,
         "commentary" : commentary,
         "datetime" : datetime
      ]
   }
}
