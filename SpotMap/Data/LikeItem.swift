//
//  LikeItem.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 07.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseDatabase

struct LikeItem {
   let userId: String
   let postId: String
   let likePlacedTime: String
   
   let ref: FIRDatabaseReference?
   
   init(who userId: String, what postId: String, at likePlacedTime: String) {
      self.userId = userId
      self.postId = postId
      self.likePlacedTime = likePlacedTime
      
      self.ref = nil
   }
   
   init(snapshot: FIRDataSnapshot) {
      let snapshotValue = snapshot.value as! [String: AnyObject]
      userId = snapshotValue["userId"] as! String
      postId = snapshotValue["postId"] as! String
      likePlacedTime = snapshotValue["likePlacedTime"] as! String
      
      ref = snapshot.ref
   }
   
   func toAnyObject() -> Any {
      return [
         "userId" : userId,
         "postId" : postId,
         "likePlacedTime" : likePlacedTime
      ]
   }
}

