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
   let commentary: String // text of comment
   let datetime: String
   
   let ref: FIRDatabaseReference?
   
   init(_ userId: String, _ postId: String, _ commentary: String, _ datetime: String, _ key: String = "") {
      self.key = key
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
      key = snapshot.key
      
      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "key" : key,
         "userId" : userId,
         "postId" : postId,
         "commentary" : commentary,
         "datetime" : datetime
      ]
   }
}
