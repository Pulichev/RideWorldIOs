//
//  CommentItem.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

class CommentItem: NSObject {
   let key: String
   
   let userId: String
   let postId: String
   let postAddedByUser: String // need this info to add to feedback, to 
   // know, if someone "commented ur post" or "mentioned you in a comment"
   let commentary: String // text of comment
   let datetime: String
   
   let feedbackKey: String
   
   let ref: FIRDatabaseReference?
   
   init(_ userId: String, _ postId: String, _ postAddedByUser: String,
        _ commentary: String, _ datetime: String,
        _ key: String) {
      self.key = key
      
      self.userId = userId
      self.postId = postId
      self.postAddedByUser = postAddedByUser
      self.commentary = commentary
      self.datetime = datetime
      
      self.feedbackKey = key
      
      self.ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      let snapshotValue = snapshot.value as! [String: AnyObject]
      key = snapshotValue["key"] as! String
      
      userId = snapshotValue["userId"] as! String
      postId = snapshotValue["postId"] as! String
      postAddedByUser = snapshotValue["postAddedByUser"] as! String
      commentary = snapshotValue["commentary"] as! String
      datetime = snapshotValue["datetime"] as! String
      
      feedbackKey = snapshotValue["feedbackKey"] as! String
      
      ref = snapshot.ref
   }
   
   func toAnyObject() -> [String: Any] {
      return [
         "key" : key,
         
         "userId" : userId,
         "postId" : postId,
         "postAddedByUser" : postAddedByUser,
         "commentary" : commentary,
         "datetime" : datetime,
         
         "feedbackKey" : feedbackKey
      ]
   }
}
